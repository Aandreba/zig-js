const std = @import("std");
const js = @import("js.zig");
const JsValue = js.JsValue;

extern fn js_string_len(idx: u32) u32;
extern fn js_string_to_zig_string(idx: u32, ptr: *u8, len: usize) u32;

pub const JsString = struct {
    value: JsValue,

    pub fn init(str: []const u8) JsString {
        return JsString{
            .value = JsValue.initString(str),
        };
    }

    pub fn len(self: *const JsString) u32 {
        return js_string_len(self.value.idx);
    }

    pub fn toZigSlice(self: *const JsString, alloc: std.mem.Allocator) ![]u8 {
        var array = try self.toZigArrayList(alloc);
        return array.toOwnedSlice();
    }

    pub fn toZigArrayList(self: *const JsString, alloc: std.mem.Allocator) !std.ArrayList(u8) {
        var mem = try std.ArrayList(u8).initCapacity(alloc, 3 * self.len());
        const finalLen = js_string_to_zig_string(self.value.idx, @ptrCast(*u8, mem.items.ptr), mem.capacity);
        mem.items.len = @intCast(usize, finalLen);
        return mem;
    }

    pub fn tryFromValue(val: JsValue) ?JsString {
        if (val.isString()) {
            return JsString{ .value = val };
        } else {
            return null;
        }
    }

    pub fn deinit(self: JsString) void {
        self.value.deinint();
    }
};
