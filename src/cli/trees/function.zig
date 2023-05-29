const std = @import("std");
const parser = @import("../parser.zig");

const Type = @import("ty.zig").Type;
const Token = parser.Token;
const Parser = parser.Parser;
const ParserError = parser.ParseError;

pub const Function = struct {
    ident: []const u8,
    args: []FunctionArgument,
    ret: ?Type,

    pub fn parse(alloc: std.mem.Allocator, p: *Parser) !Function {
        _ = try p.parseKeyword(alloc, Token.Keyword.Function);

        // Ident
        const ident = try p.nextIdent(alloc);
        errdefer alloc.free(ident);

        // Arguments
        _ = try p.parsePunctuation(alloc, Token.Punctuation.OpenParen);
        var args = std.ArrayList(FunctionArgument).init(alloc);
        errdefer {
            for (args.items) |arg| arg.deinit(alloc);
            args.deinit();
        }
        while (true) {
            const next = try p.peekToken(alloc) orelse return ParserError.UnexpectedEof;
            if (next.isThisPunctuation(Token.Punctuation.CloseParen)) break;
            try args.append(try FunctionArgument.parse(alloc, p));
        }
        try p.skipToken(alloc);

        // Return type
        var ret: ?Type = null;
        if (try p.peekToken(alloc)) |token| {
            if (Token.isThisPunctuation(token, Token.Punctuation.Colon)) {
                try p.skipToken(alloc);
                ret = try Type.parse(alloc, p);
            }
        }

        return Function{
            .ident = ident,
            .args = args.toOwnedSlice(),
            .ret = ret,
        };
    }

    pub fn parseDeclared(alloc: std.mem.Allocator, p: *Parser) !Function {
        _ = try p.parseKeyword(alloc, Token.Keyword.Declare);
        return Function.parse(alloc, p);
    }

    pub fn parseExported(alloc: std.mem.Allocator, p: *Parser) !Function {
        _ = try p.parseKeyword(alloc, Token.Keyword.Export);
        return Function.parse(alloc, p);
    }

    pub fn deinit(self: Function, alloc: std.mem.Allocator) void {
        alloc.free(self.ident);
        for (self.args) |arg| arg.deinit(alloc);
        if (self.ret) |ret| ret.deinit(alloc);
        alloc.free(self.args);
    }
};

pub const FunctionArgument = struct {
    ident: []const u8,
    ty: Type,

    pub fn parse(alloc: std.mem.Allocator, p: *Parser) !FunctionArgument {
        const ident = try p.nextIdent(alloc);
        _ = try p.parsePunctuation(alloc, Token.Punctuation.Colon);
        const ty = try Type.parse(alloc, p);

        return FunctionArgument{
            .ident = ident,
            .ty = ty,
        };
    }

    pub fn deinit(self: FunctionArgument, alloc: std.mem.Allocator) void {
        alloc.free(self.ident);
        self.ty.deinit(alloc);
    }
};
