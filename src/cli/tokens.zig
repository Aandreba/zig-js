const std = @import("std");

pub const Token = union(enum) {
    keyword: Keyword,
    punctuation: Punctuation,
    ident: []const u8,

    pub fn isKeyword(self: *const Token) bool {
        return switch (self) {
            Token.keyword => true,
            else => false,
        };
    }

    pub fn isThisKeyword(self: *const Token, kw: Token.Keyword) bool {
        return switch (self.*) {
            Token.keyword => |this| this == kw,
            else => false,
        };
    }

    pub fn isPunctuation(self: *const Token) bool {
        return switch (self) {
            Token.punctuation => true,
            else => false,
        };
    }

    pub fn isThisPunctuation(self: *const Token, punc: Token.Punctuation) bool {
        return switch (self.*) {
            Token.punctuation => |this| this == punc,
            else => false,
        };
    }

    pub fn isIdent(self: *const Token) bool {
        return switch (self) {
            Token.ident => true,
            else => false,
        };
    }

    pub fn isThisIdent(self: *const Token, ident: []const u8) bool {
        return switch (self.*) {
            Token.ident => |this| std.mem.eql(u8, this, ident),
            else => false,
        };
    }

    pub fn deinit(self: Token, alloc: std.mem.Allocator) void {
        switch (self) {
            Token.ident => |ident| alloc.free(ident),
            else => {},
        }
    }

    pub const Keyword = enum {
        Let,
        Const,
        Var,
        Readonly,
        Export,
        Class,
        Interface,
        Type,
        Declare,
        Function,
        Constructor,
        Void,
        Any,
        Unknown,
        String,
        Number,
        Boolean,
        Bigint,

        const MAP = std.ComptimeStringMap(Keyword, .{
            .{ "let", .Let },
            .{ "const", .Const },
            .{ "var", .Var },
            .{ "readonly", .Readonly },
            .{ "export", .Export },
            .{ "class", .Class },
            .{ "interface", .Interface },
            .{ "type", .Type },
            .{ "declare", .Declare },
            .{ "function", .Function },
            .{ "constructor", .Constructor },
            .{ "void", .Void },
            .{ "any", .Any },
            .{ "unknown", .Unknown },
            .{ "string", .String },
            .{ "number", .Number },
            .{ "boolean", .Boolean },
            .{ "bigint", .Bigint },
        });

        pub fn fromStr(str: []const u8) ?Keyword {
            return MAP.get(str);
        }
    };

    pub const Punctuation = enum {
        /// `,`
        Comma,
        /// `:`
        Colon,
        /// `;`
        Semi,
        /// `?`
        Question,
        /// `|`
        Pipe,
        /// `=`
        Eq,
        /// `<`
        Lt,
        /// `>`
        Gt,
        /// `(`
        OpenParen,
        /// `)`
        CloseParen,
        /// `{`
        OpenBrace,
        /// `}`
        CloseBrace,
        /// `[`
        OpenBracket,
        /// `]`
        CloseBracket,

        const MAP: [128]?Punctuation = Punctuation.generateMap();

        pub fn fromChar(c: u8) ?Punctuation {
            return MAP[@intCast(usize, c)];
        }

        fn generateMap() [128]?Punctuation {
            var result = [_]?Punctuation{null} ** 128;
            result[@intCast(usize, ',')] = .Comma;
            result[@intCast(usize, ':')] = .Colon;
            result[@intCast(usize, ';')] = .Semi;
            result[@intCast(usize, '?')] = .Question;
            result[@intCast(usize, '|')] = .Pipe;
            result[@intCast(usize, '=')] = .Eq;
            result[@intCast(usize, '<')] = .Lt;
            result[@intCast(usize, '>')] = .Gt;
            result[@intCast(usize, '(')] = .OpenParen;
            result[@intCast(usize, ')')] = .CloseParen;
            result[@intCast(usize, '{')] = .OpenBrace;
            result[@intCast(usize, '}')] = .CloseBrace;
            result[@intCast(usize, '[')] = .OpenBracket;
            result[@intCast(usize, ']')] = .CloseBracket;
            return result;
        }
    };
};
