const std = @import("std");
const JsString = @import("string.zig").JsString;

pub const JsValue = struct {
    idx: u32,

    pub const UNDEFINED: JsValue = JsValue{ .idx = 0 };
    pub const NULL: JsValue = JsValue{ .idx = 1 };
    pub const TRUE: JsValue = JsValue{ .idx = 2 };
    pub const FALSE: JsValue = JsValue{ .idx = 3 };

    pub fn init(idx: u32) JsValue {
        return JsValue{ .idx = idx };
    }

    pub fn initString(str: []const u8) JsValue {
        return JsValue.init(js_string_new(@ptrCast(*const u8, str.ptr), str.len));
    }

    pub fn initNumber(num: f64) JsValue {
        return JsValue.init(js_number_new(num));
    }

    pub fn initBoolean(val: bool) JsValue {
        if (val) {
            return JsValue.TRUE;
        } else {
            return JsValue.FALSE;
        }
    }

    pub fn isNumber(self: *const JsValue) bool {
        return js_value_is_number(self.idx) == 1;
    }

    pub fn isString(self: *const JsValue) bool {
        return js_value_is_string(self.idx) == 1;
    }

    pub fn isBoolean(self: *const JsValue) bool {
        return js_value_is_boolean(self.idx) == 1;
    }

    pub fn toJsString(self: JsValue) ?JsString {
        return JsString.tryFromValue(self);
    }

    pub fn asString(self: *const JsValue, alloc: std.mem.Allocator) !?std.ArrayList(u8) {
        if (JsString.tryFromValue(self)) |this| {
            return this.toZigArrayList(alloc);
        } else {
            return null;
        }
    }

    pub fn asNumber(self: *const JsValue) ?f64 {
        var value: f64 = undefined;
        var has_value: u8 = undefined;
        js_value_as_number(self.idx, &value, &has_value);

        if (has_value == 1) {
            return value;
        } else {
            return null;
        }
    }

    pub fn console_log(self: *const JsValue) void {
        js_console_log(self.idx);
    }

    pub fn deinint(self: JsValue) void {
        js_value_free(self.idx);
    }
};

pub fn eval(str: []const u8) JsValue {
    return JsValue.init(js_eval(@ptrCast(*const u8, str.ptr), str.len));
}

pub fn print(alloc: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
    var str = std.ArrayList(u8).init(alloc);
    defer str.deinit();

    try std.fmt.format(str.writer(), fmt, args);
    print_string(str.items);
}

pub fn print_string(str: []const u8) void {
    js_console_log_string(@ptrCast(*const u8, str.ptr), str.len);
}

extern fn js_value_free(idx: u32) void;
extern fn js_string_new(ptr: *const u8, len: usize) u32;
extern fn js_number_new(num: f64) u32;
extern fn js_boolean_new(val: bool) u32;

extern fn js_value_is_string(idx: u32) u8;
extern fn js_value_is_number(idx: u32) u8;
extern fn js_value_is_boolean(idx: u32) u8;

extern fn js_value_as_string(idx: u32, value: *f64, has_value: *u8) void;
extern fn js_value_as_number(idx: u32, value: *f64, has_value: *u8) void;

extern fn js_console_log_string(ptr: *const u8, len: usize) void;
extern fn js_console_log(idx: u32) void;
extern fn js_eval(ptr: *const u8, len: usize) u32;
