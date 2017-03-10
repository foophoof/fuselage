#![feature(lang_items)]
#![feature(asm)]
#![feature(naked_functions)]

#![no_std]
#![no_main]

use core::fmt;

#[no_mangle]
pub extern "C" fn kmain() -> ! {
    loop {
        unsafe {
            asm!("hlt" ::::: "volatile", "intel");
        }
    }
}

#[lang = "panic_fmt"]
#[no_mangle]
pub extern "C" fn rust_begin_panic(_msg: fmt::Arguments, _file: &'static str, _line: u32) -> ! {
    loop {
        unsafe {
            asm!("hlt" ::::: "volatile", "intel");
        }
    }
}
