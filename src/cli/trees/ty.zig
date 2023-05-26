const std = @import("std");
const parser = @import("../parser.zig");

const Token = parser.Token;
const Parser = parser.Parser;
const ParserError = parser.ParseError;

pub const Type = union(enum) {
    Any,
    Unkown,
    Void,
    String,
    Number,
    Bigint,

    pub fn parse(alloc: std.mem.Allocator, p: *Parser) !Type {
        _ = p;
        _ = alloc;
    }

    pub fn deinit(self: Type) void {
        _ = self;
    }
};
