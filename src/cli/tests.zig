const std = @import("std");

const Parser = @import("parser.zig").Parser;
const Token = @import("tokens.zig").Token;

const Export = @import("trees/export.zig").Export;
const Function = @import("trees/function.zig").Function;
const Type = @import("trees/ty.zig").Type;

test "parser" {
    var parse = try Parser.init("Worker.d.ts");
    defer parse.deinit(std.testing.allocator);

    const exp = try Export.parse(std.testing.allocator, &parse);
    defer exp.deinit(std.testing.allocator);

    std.debug.print("{}\n", .{exp});

    // while (try parse.nextToken(std.testing.allocator)) |token| {
    //     defer token.deinit(std.testing.allocator);
    //     std.debug.print("{}\n", .{token});
    // }
}
