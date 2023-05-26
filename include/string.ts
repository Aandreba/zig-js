import { global } from "./globals.ts";

const TEXT_ENCODER = new TextEncoder();

function js_string_len (idx: number): number {
    return (global.entries[idx].value as string).length
}

function js_string_to_zig_string (idx: number, ptr: number, len: number): number {
    const res = TEXT_ENCODER.encodeInto(global.entries[idx].value as string, new Uint8Array(global.memory.buffer).subarray(ptr, ptr + len));
    return res.written ?? len
}
