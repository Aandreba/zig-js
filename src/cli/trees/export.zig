const std = @import("std");
const parser = @import("../parser.zig");

const Function = @import("function.zig").Function;
const Type = @import("ty.zig").Type;
const Interface = @import("interface.zig").Interface;

const Parser = parser.Parser;
const Token = parser.Token;

pub const Export = union(enum) {
    Function: Function,
    Interface: Interface,

    pub fn parse(alloc: std.mem.Allocator, p: *Parser) !Export {
        _ = try p.parseKeyword(alloc, Token.Keyword.Export);

        if (try p.peekKeyword(alloc, Token.Keyword.Function)) {
            return Export{ .Function = try Function.parse(alloc, p) };
        } else if (try p.peekKeyword(alloc, Token.Keyword.Interface)) {
            return Export{ .Interface = try Interface.parse(alloc, p) };
        }

        return error.UnexpectedToken;
    }

    pub fn deinit(self: Export, alloc: std.mem.Allocator) void {
        switch (self) {
            .Function => |f| f.deinit(alloc),
            .Interface => |i| i.deinit(alloc),
        }
    }
};
