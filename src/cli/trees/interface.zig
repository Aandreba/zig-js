const std = @import("std");
const parser = @import("../parser.zig");

const Function = @import("function.zig").Function;
const Type = @import("ty.zig").Type;

const Parser = parser.Parser;
const Token = parser.Token;

pub const Interface = struct {
    name: []const u8,
    elements: std.ArrayListUnmanaged(InterfaceElement),

    pub fn parse(alloc: std.mem.Allocator, p: *Parser) !Interface {
        _ = try p.parseKeyword(alloc, Token.Keyword.Interface);

        const name = try p.nextIdent(alloc);
        errdefer alloc.free(name);

        var elements = std.ArrayListUnmanaged(InterfaceElement){};
        errdefer elements.deinit(alloc);

        _ = try p.parsePunctuation(alloc, Token.Punctuation.OpenBrace);
        while (!try p.peekPunctuation(alloc, Token.Punctuation.CloseBrace)) {
            try elements.append(alloc, try InterfaceElement.parse(alloc, p));
            _ = try p.parsePunctuation(alloc, Token.Punctuation.Semi);
        }
        try p.skipToken(alloc);

        return Interface{ .name = name, .elements = elements };
    }

    pub fn deinit(self: Interface, alloc: std.mem.Allocator) void {
        for (self.elements.items) |element| element.deinit(alloc);
        var this = self;
        this.elements.deinit(alloc);
    }
};

pub const InterfaceElement = struct {
    name: []const u8,
    ty: Type,

    pub fn parse(alloc: std.mem.Allocator, p: *Parser) !InterfaceElement {
        const name = try p.nextIdent(alloc);
        errdefer alloc.free(name);

        const optional = try p.peekPunctuation(alloc, Token.Punctuation.Question);
        if (optional) try p.skipToken(alloc);

        _ = try p.parsePunctuation(alloc, Token.Punctuation.Colon);
        var ty = try Type.parse(alloc, p);
        errdefer ty.deinit(alloc);

        if (optional) {
            ty = Type{ .sum = try alloc.dupe(Type, &[_]Type{ ty, .undefined }) };
        }

        return InterfaceElement{ .name = name, .ty = ty };
    }

    pub fn deinit(self: InterfaceElement, alloc: std.mem.Allocator) void {
        alloc.free(self.name);
        self.ty.deinit(alloc);
    }
};
