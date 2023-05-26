const std = @import("std");
const js = @import("main.zig");

const JsValue = js.JsValue;

pub const Object = struct {
    value: JsValue,

    fn init() Object {
        return JsValue.init(object_new());
    }

    fn set(self: *Object, prop: []const u8, value: JsValue) void {
        object_set(
            self.value.idx,
            @ptrCast(*const u8, prop.ptr),
            prop.len,
            value.idx,
        );
    }

    fn deinit(self: Object) void {
        self.value.deinint();
    }
};

extern fn object_new() u32;
extern fn object_set(obj: u32, ptr: *const u8, len: usize, value: u32) void; // manually drops `value`
