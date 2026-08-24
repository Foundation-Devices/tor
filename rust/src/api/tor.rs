// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

use anyhow::Result;
use arti::proxy::{self, ListenProtocols};
use arti_client::config::CfgPath;
use arti_client::{DormantMode, TorClient, TorClientConfig};
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use std::io;
use std::sync::Arc;
use tokio::runtime::{Builder, Runtime as TokioRuntime};
use tokio::task::JoinHandle;
use tor_config::Listen;
use tor_rtcompat::tokio::TokioNativeTlsRuntime;
use tor_rtcompat::{NetStreamProvider, TcpListenOptions, ToplevelBlockOn};

lazy_static! {
    static ref RUNTIME: io::Result<TokioRuntime> = Builder::new_multi_thread().enable_all().build();
}

const PROXY_SHUTDOWN_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(5);

fn create_arti_runtime() -> io::Result<(TokioNativeTlsRuntime, TokioRuntime)> {
    let runtime = Builder::new_multi_thread().enable_all().build()?;
    let handle = TokioNativeTlsRuntime::from(runtime.handle().clone());
    Ok((handle, runtime))
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
    client: Arc<TorClient<TokioNativeTlsRuntime>>,
    runtime: TokioNativeTlsRuntime,
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
    runtime: Option<TokioRuntime>,
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
    let (runtime, runtime_owner) =
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

    let proxy_handle = start_proxy_internal(socks_port, Arc::clone(&client))?;

    Ok(TorInstance {
        client: TorClientWrapper { client, runtime },
        proxy: TorProxyHandle {
            state: Arc::new(std::sync::Mutex::new(TorProxyState {
                accept_loop: Some(proxy_handle),
                runtime: Some(runtime_owner),
            })),
        },
        socks_port,
    })
}

fn start_proxy_internal(
    port: u16,
    client: Arc<TorClient<TokioNativeTlsRuntime>>,
) -> Result<JoinHandle<Result<()>>, TorError> {
    let rt = RUNTIME
        .as_ref()
        .map_err(|e| TorError::RuntimeError(e.to_string()))?;

    let runtime = client.runtime().clone();
    let listeners = runtime
        .block_on(async {
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

            Ok(listeners)
        })
        .map_err(|e: anyhow::Error| TorError::ProxyStartError(e.to_string()))?;

    Ok(rt.spawn(proxy::run_proxy_with_listeners(
        client,
        listeners,
        ListenProtocols::SocksOnly,
        None,
    )))
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
    let (accept_loop, runtime) = {
        let mut state = proxy
            .state
            .lock()
            .map_err(|e| TorError::ProxyStopError(e.to_string()))?;
        (state.accept_loop.take(), state.runtime.take())
    };

    let accept_result = match accept_loop {
        Some(handle) => {
            handle.abort();
            match RUNTIME.as_ref() {
                Ok(rt) => rt.block_on(async {
                    match tokio::time::timeout(PROXY_SHUTDOWN_TIMEOUT, handle).await {
                        Err(_) => Err(TorError::ProxyStopError(
                            "Timed out stopping Tor proxy accept loop".to_owned(),
                        )),
                        Ok(Ok(result)) => {
                            result.map_err(|e| TorError::ProxyStopError(e.to_string()))
                        }
                        Ok(Err(error)) if error.is_cancelled() => Ok(()),
                        Ok(Err(error)) => Err(TorError::ProxyStopError(error.to_string())),
                    }
                }),
                Err(error) => Err(TorError::RuntimeError(error.to_string())),
            }
        }
        None => Ok(()),
    };

    // Arti spawns one task per accepted SOCKS connection on its own runtime.
    // Shut that runtime down so even idle connections release their TorClient.
    if let Some(runtime) = runtime {
        runtime.shutdown_timeout(PROXY_SHUTDOWN_TIMEOUT);
    }

    accept_result
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
    use std::net::TcpStream;
    use std::thread;
    use std::time::{Duration, Instant};
    use tor_rtcompat::NetStreamListener;

    #[test]
    fn stop_proxy_drops_an_idle_connection() {
        let state_dir = tempfile::tempdir().unwrap();
        let cache_dir = tempfile::tempdir().unwrap();
        let config = TorClientConfigBuilder::from_directories(state_dir.path(), cache_dir.path())
            .build()
            .unwrap();
        let (runtime, runtime_owner) = create_arti_runtime().unwrap();
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
                runtime: Some(runtime_owner),
            })),
        })
        .unwrap();

        assert_eq!(Arc::strong_count(&client), baseline_client_references);
    }
}
