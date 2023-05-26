import { decode_zig_string, global, js_alloc_value } from "./globals.ts";

/* EXPORTS */
function js_value_free(idx: number) {
    global.entries[idx] = { value: undefined, next: global.next_entry };
    global.next_entry = idx;
}

function js_string_new(ptr: number, len: number): number {
    return js_alloc_value(decode_zig_string(ptr, len));
}

function js_number_new(num: number): number {
    return js_alloc_value(num)
}

function js_value_as_number(idx: number, value_: number, has_value_: number) {
    const mem = new Uint8Array(global.memory.buffer);
    let entry = global.entries[idx];

    if (typeof entry.value === 'number') {
        let value = new Float64Array(mem.buffer);
        value[value_ / Float64Array.BYTES_PER_ELEMENT] = entry.value;
        mem[has_value_] = 1;
    } else {
        mem[has_value_] = 0;
    }
}

function js_console_log_string(ptr: number, len: number) {
    console.log(decode_zig_string(ptr, len));
}

function js_console_log(idx: number) {
    console.log(global.entries[idx].value);
}

function js_eval(ptr: number, len: number): number {
    const str = decode_zig_string(ptr, len);
    return js_alloc_value(eval(str))
}

function js_value_is_string (idx: number): number {
    if (typeof global.entries[idx].value === 'string') {
        return 1
    } else {
        return 0
    }
}

function js_value_is_number (idx: number): number {
    if (typeof global.entries[idx].value === 'number') {
        return 1
    } else {
        return 0
    }
}

function js_value_is_boolean (idx: number): number {
    if (typeof global.entries[idx].value === 'boolean') {
        return 1
    } else {
        return 0
    }
}
