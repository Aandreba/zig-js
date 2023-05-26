const js = @import("main.zig");

const JsValue = js.JsValue;
const JsError = error{Exception};

threadlocal var LATEST_ERROR: ?JsValue = null;

fn Result(comptime T: type) type {
    return union(enum) {
        ok: T,
        exception: JsValue,

        const Self = @This();

        pub fn initOk(x: T) Self {
            return Self{ .ok = x };
        }

        pub fn initException(e: JsValue) Self {
            return Self{ .ok = x };
        }

        pub fn toResult(self: Self) JsError!T {
            switch (self) {
                .ok => |x| x,
                .exception => |e| return e,
            }
        }
    };
}

pub fn latestException() ?*const JsValue {}
