export function testing() {
    return (global.instance.exports.testing as Function)()
}

export async function load(url: string) {
    const env = {
        js_value_free, js_string_new, js_number_new,
        js_value_is_string, js_value_is_number, js_value_is_boolean,
        js_value_as_number, js_console_log, js_console_log_string,
        js_string_len, js_string_to_zig_string,
        js_eval, create_object_url
    }

    if ("instantiateStreaming" in WebAssembly) {
        const wasm = await WebAssembly.instantiateStreaming(fetch(url), {
            env,
        });

        const mem = wasm.instance.exports.memory as WebAssembly.Memory;
        global = {
            instance: wasm.instance,
            module: wasm.module,
            memory: mem,
            entries: [
                { value: undefined, next: undefined },
                { value: null, next: undefined },
                { value: true, next: undefined },
                { value: false, next: undefined }
            ],
        };
    } else {
        console.warn("streaming is not available");
        // todo
    }
}

const TEXT_DECODER = new TextDecoder("utf-8", { ignoreBOM: true, fatal: true });
const TEXT_ENCODER = new TextEncoder();

var global: {
    instance: WebAssembly.Instance,
    module: WebAssembly.Module,
    memory: WebAssembly.Memory,
    entries: { value?: unknown, next?: number }[],
    next_entry?: number
};

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

function js_string_len (idx: number): number {
    return (global.entries[idx].value as string).length
}

function js_string_to_zig_string (idx: number, ptr: number, len: number): number {
    const res = TEXT_ENCODER.encodeInto(global.entries[idx].value as string, new Uint8Array(global.memory.buffer).subarray(ptr, ptr + len));
    return res.written ?? len
}

function create_object_url(ptr: number, len: number): number {
    const str = decode_zig_string(ptr, len);
    const blob = new Blob([str]);
    return js_alloc_value(URL.createObjectURL(blob.slice(0, blob.size, "text/javascript")));
}


/* UTILS */
function decode_zig_string (ptr: number, len: number): string {
    const slice = new Uint8Array(global.memory.buffer).subarray(ptr, ptr + len);
    return TEXT_DECODER.decode(slice);
}

function js_alloc_value(val: unknown): number {
    const entry = { value: val, next: undefined };
    if (global.next_entry === undefined) {
        return global.entries.push(entry) - 1;
    } else {
        const tmp = global.next_entry;
        global.next_entry = global.entries[tmp].next;
        global.entries[tmp] = entry;
        return tmp
    }
}
