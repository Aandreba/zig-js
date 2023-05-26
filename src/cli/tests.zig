const std = @import("std");

const Parser = @import("parser.zig").Parser;
const Token = @import("tokens.zig").Token;

const Function = @import("trees/function.zig").Function;
const Type = @import("trees/ty.zig").Type;

test "parser" {
    var parse = try Parser.init("example.d.ts");
    defer parse.deinit(std.testing.allocator);

    const f = try Function.parseDeclared(std.testing.allocator, &parse);
    defer f.deinit(std.testing.allocator);

    std.debug.print("{s}\n", .{f.ident});

    // while (try parse.nextToken(std.testing.allocator)) |token| {
    //     defer token.deinit(std.testing.allocator);
    //     std.debug.print("{}\n", .{token});
    // }
}
