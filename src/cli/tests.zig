const std = @import("std");
const Parser = @import("parser.zig").Parser;
const Token = @import("tokens.zig").Token;

test "parser" {
    var parse = try Parser.init("example.d.ts");
    defer parse.deinit();

    while (try parse.nextToken(std.testing.allocator)) |token| {
        defer token.deinit(std.testing.allocator);
        std.debug.print("{}\n", .{token});
    }
}
