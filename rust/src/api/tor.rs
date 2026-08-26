// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

use anyhow::Result;
use arti::proxy::{self, ListenProtocols};
use arti_client::config::CfgPath;
use arti_client::{DormantMode, TorClient, TorClientConfig};
use flutter_rust_bridge::frb;
use futures::future::FutureObj;
use futures::task::{Spawn, SpawnError};
use lazy_static::lazy_static;
use std::future::Future;
use std::io;
use std::net::{Ipv4Addr, SocketAddr};
use std::sync::Arc;
use tokio::runtime::{Builder, Runtime as TokioRuntime};
use tokio::task::JoinHandle;
use tokio_util::sync::CancellationToken;
use tokio_util::task::TaskTracker;
use tor_config::Listen;
use tor_rtcompat::tokio::TokioNativeTlsRuntime;
use tor_rtcompat::{
    Blocking, CompoundRuntime, NetStreamListener, NetStreamProvider, TcpListenOptions,
    ToplevelBlockOn,
};

lazy_static! {
    static ref RUNTIME: io::Result<TokioRuntime> = Builder::new_multi_thread().enable_all().build();
}

const PROXY_SHUTDOWN_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(5);

type TrackedTorRuntime = CompoundRuntime<
    TrackedSpawner,
    TokioNativeTlsRuntime,
    TokioNativeTlsRuntime,
    TokioNativeTlsRuntime,
    TokioNativeTlsRuntime,
    TokioNativeTlsRuntime,
    TokioNativeTlsRuntime,
>;

#[derive(Clone, Debug, Default)]
struct TrackedTasks {
    tracker: TaskTracker,
    cancellation: CancellationToken,
}

impl TrackedTasks {
    fn stop_and_wait(&self) -> Result<(), TorError> {
        self.cancellation.cancel();
        self.tracker.close();
        let rt = RUNTIME
            .as_ref()
            .map_err(|error| TorError::RuntimeError(error.to_string()))?;
        if rt
            .block_on(async {
                tokio::time::timeout(PROXY_SHUTDOWN_TIMEOUT, self.tracker.wait()).await
            })
            .is_err()
        {
            Err(TorError::ProxyStopError(
                "Timed out stopping Tor client tasks".to_owned(),
            ))
        } else {
            Ok(())
        }
    }
}

#[derive(Clone, Debug)]
struct TrackedSpawner {
    runtime: TokioNativeTlsRuntime,
    tasks: TrackedTasks,
}

impl TrackedSpawner {
    fn new(runtime: TokioNativeTlsRuntime) -> Self {
        Self {
            runtime,
            tasks: TrackedTasks::default(),
        }
    }
}

impl Spawn for TrackedSpawner {
    fn spawn_obj(&self, future: FutureObj<'static, ()>) -> Result<(), SpawnError> {
        if self.tasks.tracker.is_closed() {
            return Err(SpawnError::shutdown());
        }

        let cancellation = self.tasks.cancellation.clone();
        let future = self.tasks.tracker.track_future(async move {
            tokio::select! {
                _ = cancellation.cancelled() => {}
                _ = future => {}
            }
        });
        self.runtime.spawn_obj(Box::new(future).into())
    }
}

impl Blocking for TrackedSpawner {
    type ThreadHandle<T: Send + 'static> = <TokioNativeTlsRuntime as Blocking>::ThreadHandle<T>;

    fn spawn_blocking<F, T>(&self, f: F) -> Self::ThreadHandle<T>
    where
        F: FnOnce() -> T + Send + 'static,
        T: Send + 'static,
    {
        self.runtime.spawn_blocking(f)
    }

    fn reenter_block_on<F>(&self, future: F) -> F::Output
    where
        F: Future,
        F::Output: Send + 'static,
    {
        self.runtime.reenter_block_on(future)
    }

    fn blocking_io<F, T>(&self, f: F) -> impl Future<Output = T>
    where
        F: FnOnce() -> T + Send + 'static,
        T: Send + 'static,
    {
        self.runtime.blocking_io(f)
    }
}

impl ToplevelBlockOn for TrackedSpawner {
    fn block_on<F: Future>(&self, future: F) -> F::Output {
        self.runtime.block_on(future)
    }
}

fn create_arti_runtime() -> io::Result<(TrackedTorRuntime, TrackedTasks)> {
    let runtime = TokioNativeTlsRuntime::create()?;
    let spawner = TrackedSpawner::new(runtime.clone());
    let tasks = spawner.tasks.clone();
    let runtime = CompoundRuntime::new(
        spawner,
        runtime.clone(),
        runtime.clone(),
        runtime.clone(),
        runtime.clone(),
        runtime.clone(),
        runtime,
    );
    Ok((runtime, tasks))
}

/// Custom error types for Tor operations
#[derive(Debug, thiserror::Error)]
pub enum TorError {
    #[error("Failed to bootstrap Tor: {0}")]
    BootstrapError(String),

    #[error("Failed to start proxy: {0}")]
    ProxyStartError(String),

    #[error("Failed to stop proxy: {0}")]
    ProxyStopError(String),

    #[error("Client not initialized")]
    ClientNotInitialized,

    #[error("Runtime error: {0}")]
    RuntimeError(String),

    #[error("Configuration error: {0}")]
    ConfigError(String),
}

/// Opaque wrapper for TorClient - FRB handles this automatically
#[frb(opaque)]
pub struct TorClientWrapper {
    client: Arc<TorClient<TrackedTorRuntime>>,
    runtime: TrackedTorRuntime,
}

impl Clone for TorClientWrapper {
    fn clone(&self) -> Self {
        TorClientWrapper {
            client: Arc::clone(&self.client),
            runtime: self.runtime.clone(),
        }
    }
}

/// Opaque wrapper for proxy handle
#[frb(opaque)]
pub struct TorProxyHandle {
    state: Arc<std::sync::Mutex<TorProxyState>>,
}

struct TorProxyState {
    accept_loop: Option<JoinHandle<Result<()>>>,
    tasks: Option<TrackedTasks>,
}

impl Clone for TorProxyHandle {
    fn clone(&self) -> Self {
        TorProxyHandle {
            state: Arc::clone(&self.state),
        }
    }
}

/// Result of starting Tor - contains both client and proxy
pub struct TorInstance {
    pub client: TorClientWrapper,
    pub proxy: TorProxyHandle,
    pub socks_port: u16,
}

/// Initialize FRB
#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

/// Start Tor client and proxy
///
/// This is a blocking operation that may take several seconds.
/// It bootstraps the Tor network connection and starts a SOCKS proxy.
pub fn start_tor(
    socks_port: u16,
    state_dir: String,
    cache_dir: String,
) -> Result<TorInstance, TorError> {
    let (runtime, tasks) =
        create_arti_runtime().map_err(|e| TorError::RuntimeError(e.to_string()))?;

    let mut cfg_builder = TorClientConfig::builder();
    cfg_builder
        .storage()
        .state_dir(CfgPath::new(state_dir))
        .cache_dir(CfgPath::new(cache_dir));
    cfg_builder.address_filter().allow_onion_addrs(true);
    cfg_builder
        .preemptive_circuits()
        .disable_at_threshold(1)
        .min_exit_circs_for_port(1)
        .initial_predicted_ports()
        .clear();

    let cfg = cfg_builder
        .build()
        .map_err(|e| TorError::ConfigError(e.to_string()))?;

    let client = runtime
        .block_on(async {
            TorClient::with_runtime(runtime.clone())
                .config(cfg)
                .create_bootstrapped()
                .await
        })
        .map_err(|e| TorError::BootstrapError(e.to_string()))?;

    let (proxy_handle, socks_port) = start_proxy_internal(socks_port, Arc::clone(&client))?;

    Ok(TorInstance {
        client: TorClientWrapper { client, runtime },
        proxy: TorProxyHandle {
            state: Arc::new(std::sync::Mutex::new(TorProxyState {
                accept_loop: Some(proxy_handle),
                tasks: Some(tasks),
            })),
        },
        socks_port,
    })
}

fn start_proxy_internal(
    port: u16,
    client: Arc<TorClient<TrackedTorRuntime>>,
) -> Result<(JoinHandle<Result<()>>, u16), TorError> {
    let rt = RUNTIME
        .as_ref()
        .map_err(|e| TorError::RuntimeError(e.to_string()))?;

    let runtime = client.runtime().clone();
    let (listeners, bound_port) = runtime
        .block_on(async {
            if port == 0 {
                let address = SocketAddr::from((Ipv4Addr::LOCALHOST, 0));
                let listener = runtime
                    .listen(&address, &TcpListenOptions::default())
                    .await
                    .map_err(|error| anyhow::anyhow!("Can't listen on {address}: {error}"))?;
                let bound_port = listener
                    .local_addr()
                    .map_err(|error| anyhow::anyhow!("Can't read SOCKS listener address: {error}"))?
                    .port();
                return Ok((vec![listener], bound_port));
            }

            let listen = Listen::new_localhost(port);
            let listen_options = TcpListenOptions::default();
            let mut listeners = Vec::new();

            for addrgroup in listen.ip_addrs()? {
                let mut bound_in_group = false;
                for addr in addrgroup {
                    match runtime.listen(&addr, &listen_options).await {
                        Ok(listener) => {
                            bound_in_group = true;
                            listeners.push(listener);
                        }
                        #[cfg(unix)]
                        Err(ref e) if e.raw_os_error() == Some(libc::EAFNOSUPPORT) => {}
                        Err(e) => return Err(anyhow::anyhow!("Can't listen on {addr}: {e}")),
                    }
                }

                if !bound_in_group {
                    return Err(anyhow::anyhow!(
                        "Couldn't open any SOCKS listener in address group"
                    ));
                }
            }

            if listeners.is_empty() {
                return Err(anyhow::anyhow!("Couldn't open SOCKS listeners"));
            }

            Ok((listeners, port))
        })
        .map_err(|e: anyhow::Error| TorError::ProxyStartError(e.to_string()))?;

    Ok((
        rt.spawn(proxy::run_proxy_with_listeners(
            client,
            listeners,
            ListenProtocols::SocksOnly,
            None,
        )),
        bound_port,
    ))
}

/// Re-bootstrap the Tor client
///
/// Call this after network changes or to refresh the connection.
pub fn bootstrap(client: &TorClientWrapper) -> Result<(), TorError> {
    client
        .runtime
        .block_on(client.client.as_ref().bootstrap())
        .map_err(|e| TorError::BootstrapError(e.to_string()))
}

/// Set the client dormant mode
///
/// * `soft_mode` - If true, uses Soft dormant mode (keeps some circuits warm)
///   If false, uses Normal mode (full operation)
pub fn set_dormant(client: &TorClientWrapper, soft_mode: bool) {
    let dormant_mode = if soft_mode {
        DormantMode::Soft
    } else {
        DormantMode::Normal
    };
    client.client.as_ref().set_dormant(dormant_mode);
}

/// Stop the Tor proxy
///
/// Stops the accept loop and the client runtime that owns accepted connections.
pub fn stop_proxy(proxy: TorProxyHandle) -> Result<(), TorError> {
    let (accept_loop, tasks) = {
        let mut state = proxy
            .state
            .lock()
            .map_err(|e| TorError::ProxyStopError(e.to_string()))?;
        (state.accept_loop.take(), state.tasks.take())
    };

    let accept_result = match accept_loop {
        Some(handle) => {
            handle.abort();
            match RUNTIME.as_ref() {
                Ok(rt) => rt.block_on(async {
                    // A loop that already ended - by its own error or a panic -
                    // has released its listeners and client clone, so only an
                    // unfinished task leaves teardown unconfirmed.
                    match tokio::time::timeout(PROXY_SHUTDOWN_TIMEOUT, handle).await {
                        Err(_) => Err(TorError::ProxyStopError(
                            "Timed out stopping Tor proxy accept loop".to_owned(),
                        )),
                        Ok(Ok(Err(error))) => {
                            log::warn!("Tor proxy accept loop had already failed: {error}");
                            Ok(())
                        }
                        Ok(Err(error)) if !error.is_cancelled() => {
                            log::warn!("Tor proxy accept loop panicked: {error}");
                            Ok(())
                        }
                        Ok(_) => Ok(()),
                    }
                }),
                Err(error) => Err(TorError::RuntimeError(error.to_string())),
            }
        }
        None => Ok(()),
    };

    let task_result = tasks.map_or(Ok(()), |tasks| tasks.stop_and_wait());

    accept_result.and(task_result)
}

/// Test function to verify library linking
pub fn hello() {
    println!("HELLO THERE");
}

// Platform-specific rlimit functions
#[cfg(not(target_os = "windows"))]
pub fn get_nofile_limit() -> Result<u64, TorError> {
    rlimit::getrlimit(rlimit::Resource::NOFILE)
        .map(|(soft, _hard)| soft)
        .map_err(|e| TorError::RuntimeError(e.to_string()))
}

#[cfg(not(target_os = "windows"))]
pub fn set_nofile_limit(limit: u64) -> Result<u64, TorError> {
    rlimit::increase_nofile_limit(limit).map_err(|e| TorError::RuntimeError(e.to_string()))
}

#[cfg(target_os = "windows")]
pub fn get_nofile_limit() -> Result<u64, TorError> {
    Ok(0) // Not applicable on Windows
}

#[cfg(target_os = "windows")]
pub fn set_nofile_limit(_limit: u64) -> Result<u64, TorError> {
    Ok(0) // Not applicable on Windows
}

#[cfg(test)]
mod tests {
    use super::*;
    use arti_client::config::TorClientConfigBuilder;
    use std::net::{TcpListener, TcpStream};
    use std::thread;
    use std::time::{Duration, Instant};
    use tor_rtcompat::NetStreamListener;

    #[test]
    fn proxy_selects_and_holds_its_ephemeral_port() {
        let state_dir = tempfile::tempdir().unwrap();
        let cache_dir = tempfile::tempdir().unwrap();
        let config = TorClientConfigBuilder::from_directories(state_dir.path(), cache_dir.path())
            .build()
            .unwrap();
        let (runtime, tasks) = create_arti_runtime().unwrap();
        let client = TorClient::with_runtime(runtime.clone())
            .config(config)
            .create_unbootstrapped()
            .unwrap();

        let (proxy_task, port) = start_proxy_internal(0, Arc::clone(&client)).unwrap();

        assert_ne!(port, 0);
        assert!(
            TcpListener::bind((Ipv4Addr::LOCALHOST, port)).is_err(),
            "the published SOCKS port was not retained by the proxy"
        );

        stop_proxy(TorProxyHandle {
            state: Arc::new(std::sync::Mutex::new(TorProxyState {
                accept_loop: Some(proxy_task),
                tasks: Some(tasks),
            })),
        })
        .unwrap();

        TcpListener::bind((Ipv4Addr::LOCALHOST, port)).unwrap();
    }

    #[test]
    fn proxy_start_fails_when_a_requested_port_is_already_owned() {
        let state_dir = tempfile::tempdir().unwrap();
        let cache_dir = tempfile::tempdir().unwrap();
        let config = TorClientConfigBuilder::from_directories(state_dir.path(), cache_dir.path())
            .build()
            .unwrap();
        let (runtime, _tasks) = create_arti_runtime().unwrap();
        let client = TorClient::with_runtime(runtime)
            .config(config)
            .create_unbootstrapped()
            .unwrap();
        let occupied = TcpListener::bind((Ipv4Addr::LOCALHOST, 0)).unwrap();
        let port = occupied.local_addr().unwrap().port();

        let result = start_proxy_internal(port, client);

        assert!(matches!(result, Err(TorError::ProxyStartError(_))));
    }

    #[test]
    fn stop_proxy_drops_an_idle_connection() {
        let state_dir = tempfile::tempdir().unwrap();
        let cache_dir = tempfile::tempdir().unwrap();
        let config = TorClientConfigBuilder::from_directories(state_dir.path(), cache_dir.path())
            .build()
            .unwrap();
        let (runtime, tasks) = create_arti_runtime().unwrap();
        let client = TorClient::with_runtime(runtime.clone())
            .config(config)
            .create_unbootstrapped()
            .unwrap();
        let baseline_client_references = Arc::strong_count(&client);
        let listen_address: std::net::SocketAddr = "127.0.0.1:0".parse().unwrap();
        let (listener, address) = runtime.block_on(async {
            let listener = runtime
                .listen(&listen_address, &TcpListenOptions::default())
                .await
                .unwrap();
            let address = listener.local_addr().unwrap();
            (listener, address)
        });
        let proxy_task = RUNTIME
            .as_ref()
            .unwrap()
            .spawn(proxy::run_proxy_with_listeners(
                Arc::clone(&client),
                vec![listener],
                ListenProtocols::SocksOnly,
                None,
            ));
        let _idle_connection = TcpStream::connect(address).unwrap();

        let deadline = Instant::now() + Duration::from_secs(1);
        while Arc::strong_count(&client) <= baseline_client_references + 1
            && Instant::now() < deadline
        {
            thread::sleep(Duration::from_millis(10));
        }
        assert!(
            Arc::strong_count(&client) > baseline_client_references + 1,
            "the idle connection was not accepted"
        );

        stop_proxy(TorProxyHandle {
            state: Arc::new(std::sync::Mutex::new(TorProxyState {
                accept_loop: Some(proxy_task),
                tasks: Some(tasks),
            })),
        })
        .unwrap();

        assert_eq!(Arc::strong_count(&client), baseline_client_references);
    }

    #[test]
    fn stop_proxy_succeeds_when_the_accept_loop_already_failed() {
        let accept_loop = RUNTIME
            .as_ref()
            .unwrap()
            .spawn(async { Err(anyhow::anyhow!("fatal accept error")) });

        let deadline = Instant::now() + Duration::from_secs(1);
        while !accept_loop.is_finished() && Instant::now() < deadline {
            thread::sleep(Duration::from_millis(10));
        }
        assert!(accept_loop.is_finished(), "the accept loop did not finish");

        // A proxy that already died is exactly when the caller has to be able
        // to restart, so a stale accept-loop error must not fail teardown.
        stop_proxy(TorProxyHandle {
            state: Arc::new(std::sync::Mutex::new(TorProxyState {
                accept_loop: Some(accept_loop),
                tasks: None,
            })),
        })
        .unwrap();
    }
}
