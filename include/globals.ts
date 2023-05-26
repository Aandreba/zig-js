export let global: {
    instance: WebAssembly.Instance,
    module: WebAssembly.Module,
    memory: WebAssembly.Memory,
    entries: { value?: unknown, next?: number }[],
    next_entry?: number
};

const TEXT_DECODER = new TextDecoder("utf-8", { ignoreBOM: true, fatal: true });

/* UTILS */
export function decode_zig_string (ptr: number, len: number): string {
    const slice = new Uint8Array(global.memory.buffer).subarray(ptr, ptr + len);
    return TEXT_DECODER.decode(slice);
}

export function js_alloc_value(val: unknown): number {
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
