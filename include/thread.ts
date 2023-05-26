import { decode_zig_string, js_alloc_value } from "./globals.ts";

function create_object_url(ptr: number, len: number): number {
    const str = decode_zig_string(ptr, len);
    const blob = new Blob([str]);
    return js_alloc_value(URL.createObjectURL(blob.slice(0, blob.size, "text/javascript")));
}
