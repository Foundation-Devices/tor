// Just an example that's runnable with `cargo run`, demo not meant for actual use
fn main () {}
/*
use tor_sys::*;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::thread;

static mut STARTED: bool = false;

fn main () {
    println!("1");
    /*thread::spawn(move || {*/
    println!("2");
        unsafe { // TODO reduce scope
            println!("2");
            let config = tor_main_configuration_new();
            
            println!("2");
            // Convert the pointer to a &CStr
            let c_str = CStr::from_ptr(config as *const i8);
            // Convert the CStr to a string if it contains valid UTF-8 data
            if let Ok(str_slice) = c_str.to_str() {
                let string_data = str_slice.to_owned();
                println!("String: {}", string_data);
            } else {
                println!("Invalid UTF-8 data");
            }
            
            let argv = vec![
                CString::new("tor").unwrap(),
                CString::new("-f").unwrap(),
                CString::new("~/.stackwallet/torrc").unwrap(),
            ];
            let argv: Vec<_> = argv.iter().map(|s| s.as_ptr()).collect();
            tor_main_configuration_set_command_line(config, argv.len() as i32, argv.as_ptr());
            tor_run_main(config);
            tor_main_configuration_free(config);
        }
    // });
}

#[no_mangle]
pub unsafe extern "C" fn tor_start(conf_path: *const c_char) -> bool {
    if !STARTED {
        STARTED = true;
        let path = CStr::from_ptr(conf_path).to_str().unwrap();
        thread::spawn(move || {
            let config = tor_main_configuration_new();
            let argv = vec![
                CString::new("tor").unwrap(),
                CString::new("-f").unwrap(),
                CString::new(path).unwrap(),
            ];
            let argv: Vec<_> = argv.iter().map(|s| s.as_ptr()).collect();
            tor_main_configuration_set_command_line(config, argv.len() as i32, argv.as_ptr());
            tor_run_main(config);
            tor_main_configuration_free(config);
            STARTED = false;
        });
        return true;
    }
    false
}
*/
