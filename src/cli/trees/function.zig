const std = @import("std");
const parser = @import("../parser.zig");

const Type = @import("ty.zig").Type;
const Token = parser.Token;
const Parser = parser.Parser;
const ParserError = parser.ParseError;

pub const Function = struct {
    ident: []const u8,
    alloc: std.mem.Allocator,

    pub fn parse(alloc: std.mem.Allocator, p: *Parser) !Function {
        _ = try p.parseKeyword(alloc, Token.Keyword.Function);

        const ident = try p.nextIdent(alloc);
        errdefer alloc.free(ident);

        _ = try p.parsePunctuation(alloc, Token.Punctuation.OpenParen);
    }

    pub fn deinit(self: Function) void {
        self.alloc.free(self.ident);
    }
};

pub const FunctionArgument = struct {
    ident: []const u8,
    ty: Type,
};
