// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

use anyhow::Result;
use arti::proxy;
use arti_client::config::CfgPath;
use arti_client::{DormantMode, TorClient, TorClientConfig};
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use std::io;
use std::sync::Arc;
use tokio::runtime::{Builder, Runtime};
use tokio::task::JoinHandle;
use tor_config::Listen;
use tor_rtcompat::tokio::TokioNativeTlsRuntime;
use tor_rtcompat::ToplevelBlockOn;

lazy_static! {
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread().enable_all().build();
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
    handle: Arc<std::sync::Mutex<Option<JoinHandle<Result<()>>>>>,
}

impl Clone for TorProxyHandle {
    fn clone(&self) -> Self {
        TorProxyHandle {
            handle: Arc::clone(&self.handle),
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
    let runtime = TokioNativeTlsRuntime::create()
        .map_err(|e| TorError::RuntimeError(e.to_string()))?;

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

    let client = runtime.block_on(async {
        TorClient::with_runtime(runtime.clone())
            .config(cfg)
            .create_bootstrapped()
            .await
    })
    .map_err(|e| TorError::BootstrapError(e.to_string()))?;

    let client_arc = Arc::new(client);
    let proxy_handle = start_proxy_internal(socks_port, Arc::clone(&client_arc))?;

    Ok(TorInstance {
        client: TorClientWrapper {
            client: client_arc,
            runtime,
        },
        proxy: TorProxyHandle {
            handle: Arc::new(std::sync::Mutex::new(Some(proxy_handle))),
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

    let client_ref = client.as_ref();
    Ok(rt.spawn(proxy::run_proxy(
        client_ref.runtime().clone(),
        client_ref.clone(),
        Listen::new_localhost(port),
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
///                 If false, uses Normal mode (full operation)
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
/// This safely aborts the proxy task. Previously this could panic
/// and crash the app - with FRB, any panic becomes a catchable exception.
pub fn stop_proxy(proxy: TorProxyHandle) -> Result<(), TorError> {
    // Take the handle out of the Option to abort it
    // This ensures we only abort once even if called multiple times
    let mut guard = proxy
        .handle
        .lock()
        .map_err(|e| TorError::ProxyStopError(e.to_string()))?;

    if let Some(handle) = guard.take() {
        // The abort() call is safe with FRB - any panic becomes PanicException
        handle.abort();
    }

    Ok(())
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
