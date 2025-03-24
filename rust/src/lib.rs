// SPDX-FileCopyrightText: 2023 Foundation Devices Inc.
// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

use crate::error::update_last_error;
use arti::socks;
use arti_client::config::CfgPath;
use arti_client::{DormantMode, TorClient, TorClientConfig};
use lazy_static::lazy_static;
use std::ffi::{c_char, c_void, CStr, CString};
use std::{io, ptr};
use tokio::runtime::{Builder, Runtime};
use tokio::task::JoinHandle;
use tor_config::Listen;
use tor_rtcompat::tokio::TokioNativeTlsRuntime;
use tor_rtcompat::BlockOn;
use tor_dirmgr::Timeliness;
use tor_circmgr::isolation::StreamIsolation;
use tor_circmgr::DirInfo;

pub use crate::error::tor_last_error_message;
#[cfg(not(target_os = "windows"))]
pub use crate::util::tor_get_nofile_limit;
#[cfg(not(target_os = "windows"))]
pub use crate::util::tor_set_nofile_limit;

#[macro_use]
mod error;
mod util;

lazy_static! {
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread().enable_all().build();
}

#[repr(C)]
pub struct Tor {
    client: *mut c_void,
    proxy: *mut c_void,
}

#[no_mangle]
pub unsafe extern "C" fn tor_start(
    socks_port: u16,
    state_dir: *const c_char,
    cache_dir: *const c_char,
) -> Tor {
    let err_ret = Tor {
        client: ptr::null_mut(),
        proxy: ptr::null_mut(),
    };

    let state_dir = unwrap_or_return!(CStr::from_ptr(state_dir).to_str(), err_ret);
    let cache_dir = unwrap_or_return!(CStr::from_ptr(cache_dir).to_str(), err_ret);

    let runtime = unwrap_or_return!(TokioNativeTlsRuntime::create(), err_ret);

    let mut cfg_builder = TorClientConfig::builder();
    cfg_builder
        .storage()
        .state_dir(CfgPath::new(state_dir.to_owned()))
        .cache_dir(CfgPath::new(cache_dir.to_owned()));
    cfg_builder.address_filter().allow_onion_addrs(true);

    let cfg = unwrap_or_return!(cfg_builder.build(), err_ret);

    let client = unwrap_or_return!(
        runtime.block_on(async {
            TorClient::with_runtime(runtime.clone())
                .config(cfg)
                .create_bootstrapped()
                .await
        }),
        err_ret
    );

    let proxy_handle_box = Box::new(start_proxy(socks_port, client.clone()));
    let client_box = Box::new(client.clone());

    Tor {
        client: Box::into_raw(client_box) as *mut c_void,
        proxy: Box::into_raw(proxy_handle_box) as *mut c_void,
    }
}

#[no_mangle]
pub unsafe extern "C" fn tor_client_bootstrap(client: *mut c_void) -> bool {
    let client = {
        assert!(!client.is_null());
        Box::from_raw(client as *mut TorClient<TokioNativeTlsRuntime>)
    };

    unwrap_or_return!(client.runtime().block_on(client.bootstrap()), false);
    true
}

#[no_mangle]
pub unsafe extern "C" fn tor_client_set_dormant(client: *mut c_void, soft_mode: bool) {
    let client = {
        assert!(!client.is_null());
        Box::from_raw(client as *mut TorClient<TokioNativeTlsRuntime>)
    };

    let dormant_mode = if soft_mode {
        DormantMode::Soft
    } else {
        DormantMode::Normal
    };
    client.set_dormant(dormant_mode);
    Box::leak(client);
}

#[no_mangle]
pub unsafe extern "C" fn tor_proxy_stop(proxy: *mut c_void) {
    let proxy = {
        assert!(!proxy.is_null());
        Box::from_raw(proxy as *mut JoinHandle<anyhow::Result<()>>)
    };

    proxy.abort();
}

fn start_proxy(
    port: u16,
    client: TorClient<TokioNativeTlsRuntime>,
) -> JoinHandle<anyhow::Result<()>> {
    println!("Starting proxy!");
    let rt = RUNTIME.as_ref().unwrap();
    rt.spawn(socks::run_socks_proxy(
        client.runtime().clone(),
        client.clone(),
        Listen::new_localhost(port),
    ))
}

/// Get the exit node's identity (e.g., nickname or ID) for the given client.
#[no_mangle]
pub unsafe extern "C" fn tor_get_exit_node(client: *mut c_void) -> *mut c_char {
    let client = {
        assert!(!client.is_null());
        &*(client as *mut TorClient<TokioNativeTlsRuntime>)
    };

    let runtime = client.runtime().clone();

    let result = runtime.block_on(async {
        if let Ok(netdir) = client.dirmgr().netdir(Timeliness::Timely) {
            let circmgr = client.circmgr();

            let ports = &[];
            let isolation = StreamIsolation::no_isolation();

            // Get or launch an exit circuit.
            match circmgr.get_or_launch_exit(DirInfo::Directory(&netdir), ports, isolation).await {
                Ok(circuit) => {
                    let path = circuit.path_ref();
                    if let Some(exit_hop) = path.hops().last() {
                        let exit_info = format!("{}", exit_hop);
                        Ok(exit_info)
                    } else {
                        Err("No exit hop in circuit".to_string())
                    }
                }
                Err(e) => Err(format!("Failed to get circuit: {:?}", e)),
            }
        } else {
            Err("No NetDir available".to_string())
        }
    });

    match result {
        Ok(exit_info) => {
            CString::new(exit_info).unwrap().into_raw()
        }
        Err(err) => {
            update_last_error(std::io::Error::new(std::io::ErrorKind::Other, err));
            std::ptr::null_mut()
        }
    }
}

/// Free a C string allocated by this library.
///
/// Used to free memory allocated by functions like `tor_get_exit_node`.
#[no_mangle]
pub unsafe extern "C" fn tor_free_string(s: *mut c_char) {
    if !s.is_null() {
        drop(CString::from_raw(s));
    }
}

// Due to its simple signature this dummy function is the one added (unused) to iOS swift codebase to force Xcode to link the lib
#[no_mangle]
pub unsafe extern "C" fn tor_hello() {
    println!("HELLO THERE");
}
