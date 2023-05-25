const std = @import("std");
const js = @import("js.zig");

const JsValue = js.JsValue;
const JsString = @import("string.zig").JsString;

var SCRIPT_URL: ?JsString = null;

pub const Thread = struct {
    worker: JsValue,

    fn spawn(alloc: std.mem.Allocator, f: anytype, args: anytype) !Thread {
        // Create context
        const ctx = try alloc.create(WorkerContext);
        ctx.* = try WorkerContext.init(alloc, f, args);
        errdefer alloc.destroy(ctx);

        // TODO worker options

        const script = try get_worker_script(alloc);
        _ = script;
    }

    fn deinit(self: Thread) void {
        self.worker.deinint();
    }
};

const WorkerContext = struct {
    f: *const fn (*anyopaque) void,
    args: *anyopaque,
    alloc: std.mem.Allocator,

    /// Creates context with information to run worker's callback
    pub fn init(alloc: std.mem.Allocator, f: anytype, args: anytype) !WorkerContext {
        const Args = @TypeOf(args);

        const Instance = struct {
            fn entryFn(raw_arg: *anyopaque) void {
                // @alignCast() below doesn't support zero-sized-types (ZST)
                if (@sizeOf(Args) < 1) {
                    return @call(.auto, f, @as(Args, undefined));
                }

                const args_ptr = @ptrCast(*Args, @alignCast(@alignOf(Args), raw_arg));
                defer alloc.destroy(args_ptr);
                @call(.auto, f, args_ptr.*);
            }
        };

        const args_ptr = try alloc.create(Args);
        args_ptr.* = args;
        errdefer alloc.destroy(args_ptr);

        return WorkerContext{
            .f = Instance.entryFn,
            .args = args_ptr,
            .alloc = alloc,
        };
    }

    pub fn call(self: *WorkerContext) void {
        (self.f)(self.args);
    }
};

/// Extracts path of the `wasm_bindgen` generated .js shim script
fn get_wasm_bindgen_shim_script_path(alloc: std.mem.Allocator) !std.ArrayList(u8) {
    const res = js.eval(@embedFile("thread/script_path.js"));
    if (JsString.tryFromValue(res)) |str| {
        return str.toZigArrayList(alloc);
    } else unreachable;
}

/// Generates worker entry script as URL encoded blob
fn get_worker_script_with_shim(alloc: std.mem.Allocator, wasm_bindgen_shim_url: []const u8) !JsString {
    const WORKER = @embedFile("thread/worker.js");
    const NEEDLE = "WASM_BINDGEN_SHIM_URL";

    var template = try alloc.alloc(u8, WORKER.len - NEEDLE.len + wasm_bindgen_shim_url.len);
    defer alloc.free(template);

    _ = std.mem.replace(u8, WORKER, NEEDLE, wasm_bindgen_shim_url, template);
    const value = JsValue.init(create_object_url(
        @ptrCast(*const u8, template.ptr),
        template.len,
    ));
    return JsString.tryFromValue(value) orelse unreachable;
}

/// Generates worker entry script as URL encoded blob
pub fn get_worker_script(alloc: std.mem.Allocator) !*const JsString {
    if (SCRIPT_URL == null) {
        const shim = try get_wasm_bindgen_shim_script_path(alloc);
        defer shim.deinit();
        SCRIPT_URL = try get_worker_script_with_shim(alloc, shim.items);
    }

    if (SCRIPT_URL) |*url| {
        return url;
    } else unreachable;
}

fn load_module_workers_polyfill() void {
    _ = js.eval(@embedFile("js/thread/module_workers.js"));
}

// #[wasm_bindgen(module = "/src/module_workers_polyfill.min.js")]
// extern fn load_module_workers_polyfill() void;
extern fn create_object_url(ptr: *const u8, len: usize) u32;

export fn wasm_thread_entry_point(ptr: *anyopaque) void {
    const ctx = @ptrCast(*WorkerContext, @alignCast(@alignOf(WorkerContext), ptr));
    ctx.call();
}
