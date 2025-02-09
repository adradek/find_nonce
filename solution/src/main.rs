use sha2::{Sha256, Digest};
use std::time::Instant;
use std::thread;
use std::sync::{atomic::{AtomicBool, Ordering}, Arc, Mutex};

// const BASE_TEXT: &str = "blockchain";
const BASE_TEXT: &str = "hello world ";
const REQUEST_PREFIX: &str = "0000000";
const STARTING_NONCE: i64 = 1_645_901_534;

fn main() {
    let start = Instant::now();
    // let (found, hash) = simple_run();
    let (found, hash) = multi_run(2);
    let duration = start.elapsed();

    println!("[{}]:({:?}) {}: {}", found - STARTING_NONCE, duration, found, hash);
}

#[allow(dead_code)]
fn simple_run() -> (i64, String) {
    let mut nonce = STARTING_NONCE;
    let size = REQUEST_PREFIX.len();
    let mut base_hasher = Sha256::new();
    base_hasher.update(BASE_TEXT);

    loop {
        let mut hasher = base_hasher.clone();
        hasher.update(nonce.to_string());

        let hash = format!("{:x}", &hasher.finalize());

        // if hash.starts_with(REQUEST_PREFIX) {
        if &hash[..size] == REQUEST_PREFIX {
            return (nonce, hash);
        }

        nonce += 1;
    }
}

#[allow(dead_code)]
fn multi_run(num_threads: usize) ->(i64, String) {
    let found_flag = Arc::new(AtomicBool::new(false));
    let result = Arc::new(Mutex::new(None));

    let mut base_hasher = Sha256::new();
    base_hasher.update(BASE_TEXT.as_bytes());

    let mut handles = Vec::with_capacity(num_threads);

    for thread_id in 0..num_threads {
        let found_flag_clone = Arc::clone(&found_flag);
        let result_clone = Arc::clone(&result);
        let base_hasher_clone = base_hasher.clone();

        let handle = thread::spawn(move || {
            let mut nonce = STARTING_NONCE + thread_id as i64;
            while !found_flag_clone.load(Ordering::Relaxed) {
                let mut hasher = base_hasher_clone.clone();
                hasher.update(nonce.to_string().as_bytes());

                let hash = format!("{:x}", hasher.finalize());

                if hash.starts_with(REQUEST_PREFIX) {
                    let mut locked_result = result_clone.lock().unwrap();
                    *locked_result = Some((nonce, hash));
                    found_flag_clone.store(true, Ordering::Relaxed);
                    break;
                }

                nonce += num_threads as i64;
            }
        });

        handles.push(handle);
    }

    for handle in handles { let _ = handle.join(); }

    let locked_result = result.lock().unwrap();
    locked_result.clone().unwrap()
}
