//! tor-netdoc reads `SystemTime::min_value()` while parsing every consensus.
//! Upstream saturating-time 0.5.0 never finishes computing it on Windows,
//! where `SystemTime` has 100ns resolution, so bootstrap hung forever.

use saturating_time::SaturatingTime;
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, Instant, SystemTime};

#[test]
fn time_limits_are_found_on_this_platform() {
    let (tx, rx) = mpsc::channel();
    thread::spawn(move || {
        let limits = (
            SystemTime::min_value(),
            SystemTime::max_value(),
            Instant::min_value(),
            Instant::max_value(),
        );
        tx.send(limits).unwrap();
    });

    let (min_time, max_time, min_instant, max_instant) = rx
        .recv_timeout(Duration::from_secs(10))
        .expect("saturating-time limits did not resolve");

    assert!(min_time < SystemTime::UNIX_EPOCH);
    assert!(max_time > SystemTime::now());
    assert!(min_time.checked_sub(Duration::from_secs(1)).is_none());
    assert!(max_time.checked_add(Duration::from_secs(1)).is_none());
    assert!(min_instant < max_instant);
}
