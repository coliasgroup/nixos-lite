#![no_std]

// SPDX-License-Identifier: GPL-2.0

extern crate kernel;

use core::str;

use kernel::prelude::*;

module! {
    type: ModuleImpl,
    name: "rust_with_cargo",
    author: "Nick Spinale",
    description: "Sample Rust out-of-tree module built using with Cargo",
    license: "GPL",
}

pub struct ModuleImpl {}

impl kernel::Module for ModuleImpl {
    fn init(_module: &'static ThisModule) -> Result<Self> {
        pr_info!("Hello\n");

        let msg = "736563726574206D657373616765";

        let mut buf = Vec::new();
        for _ in 0..(msg.len() / 2) {
            buf.push(0, GFP_KERNEL).unwrap();
        }

        hex::decode_to_slice(msg, &mut buf).unwrap();

        pr_info!("Decoded: {}\n", str::from_utf8(&buf).unwrap());

        Ok(ModuleImpl {})
    }
}

impl Drop for ModuleImpl {
    fn drop(&mut self) {
        pr_info!("Goodbye\n");
    }
}
