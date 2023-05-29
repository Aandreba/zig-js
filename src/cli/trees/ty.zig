const std = @import("std");
const parser = @import("../parser.zig");

const Token = parser.Token;
const Parser = parser.Parser;
const ParserError = parser.ParseError;

pub const Type = union(enum) {
    any,
    unknown,
    void_,
    string,
    number,
    boolean,
    bigint,
    null,
    undefined,
    array: *Type,
    tuple: []Type,
    ident: []const u8,
    sum: []Type,

    pub fn parse(alloc: std.mem.Allocator, p: *Parser) !Type {
        const token = try p.nextToken(alloc) orelse return ParserError.UnexpectedEof;
        errdefer token.deinit(alloc);

        switch (token) {
            Token.ident => |ident| return Type{ .ident = ident },
            Token.keyword => |kw| switch (kw) {
                Token.Keyword.Any => return Type.any,
                Token.Keyword.Unknown => return Type.unknown,
                Token.Keyword.Void => return Type.void_,
                Token.Keyword.String => return Type.string,
                Token.Keyword.Number => return Type.number,
                Token.Keyword.Boolean => return Type.boolean,
                Token.Keyword.Null => return Type.null,
                Token.Keyword.Undefined => return Type.undefined,
                else => return ParserError.UnexpectedToken,
            },
            Token.punctuation => |punc| switch (punc) {
                Token.Punctuation.OpenBracket => {
                    var next = try p.peekToken(alloc) orelse return ParserError.UnexpectedEof;

                    if (next.isThisPunctuation(Token.Punctuation.CloseBracket)) {
                        // Array
                        const ty = try Type.parse(alloc, p);
                        errdefer ty.deinit(alloc);

                        const ptr = try alloc.create(Type);
                        ptr.* = ty;
                        return Type{ .array = ptr };
                    } else {
                        // Tuple
                        var types = std.ArrayList(Type).init(alloc);
                        errdefer {
                            for (types.items) |ty| ty.deinit(alloc);
                            types.deinit();
                        }

                        while (!next.isThisPunctuation(Token.Punctuation.CloseBracket)) {
                            try types.append(try Type.parse(alloc, p));
                            next = try p.peekToken(alloc) orelse return ParserError.UnexpectedEof;
                        }

                        return Type{ .tuple = types.toOwnedSlice() };
                    }
                },
                else => return ParserError.UnexpectedToken,
            },
        }
    }

    pub fn deinit(self: Type, alloc: std.mem.Allocator) void {
        switch (self) {
            Type.array => |*ty| {
                ty.*.deinit(alloc);
                alloc.destroy(ty);
            },
            Type.tuple, Type.sum => |types| {
                for (types) |ty| ty.deinit(alloc);
                alloc.free(types);
            },
            Type.ident => |ident| alloc.free(ident),
            else => {},
        }
    }
};
