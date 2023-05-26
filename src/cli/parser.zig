const std = @import("std");

pub const Token = @import("tokens.zig").Token;
pub const ParseError = error{ NonAscii, UnexpectedToken, UnexpectedEof };

pub const Parser = struct {
    file: std.fs.File,
    reader: std.fs.File.Reader,
    peek: ??Token,

    pub fn init(path: []const u8) !Parser {
        const cwd = std.fs.cwd();
        var file = try cwd.openFile(path, .{});

        return Parser{
            .reader = file.reader(),
            .file = file,
            .peek = null,
        };
    }

    pub fn nextToken(self: *Parser, alloc: std.mem.Allocator) !?Token {
        if (self.peek) |peek| {
            self.peek = null;
            return peek;
        }

        // Punctuation
        const b = try self.skipWhitespace() orelse return null;
        if (Token.Punctuation.fromChar(b)) |punc| return Token{ .Punctuation = punc };

        // Skip comments
        if (b == '/') {
            const next = try self.reader.readByte();
            if (next == '/') {
                // Single line
                try self.reader.skipUntilDelimiterOrEof('\n');
                return self.nextToken(alloc);
            } else if (next == '*') {
                // Multi line
                var prev: ?u8 = null;
                var curr: u8 = try self.reader.readByte();

                while (true) {
                    prev = curr;
                    curr = try self.reader.readByte();
                    if (curr == '/' and prev == @as(u8, '*')) {
                        break;
                    }
                }

                return self.nextToken(alloc);
            } else {
                try self.file.seekBy(-1);
            }
        }

        // Read 'Ident'
        try self.file.seekBy(-1);
        var ident = try std.ArrayList(u8).initCapacity(alloc, 1);
        errdefer ident.deinit();

        while (true) {
            const c = try self.reader.readByte();
            if (!std.ascii.isASCII(c)) return ParseError.NonAscii;
            if (!std.ascii.isAlphanumeric(c)) {
                try self.file.seekBy(-1);
                break;
            }
            try ident.append(c);
        }

        // Keyword
        if (Token.Keyword.fromStr(ident.items)) |kw| {
            ident.deinit();
            return Token{ .Keyword = kw };
        }

        return Token{ .Ident = ident.toOwnedSlice() };
    }

    pub fn peekToken(self: *Parser, alloc: std.mem.Allocator) !?*const Token {
        const next_token = try self.nextToken(alloc);
        self.peek = next_token;
        return &self.peek;
    }

    pub fn nextIdent(self: *Parser, alloc: std.mem.Allocator) ![]const u8 {
        const token = try self.nextToken(alloc) orelse return ParseError.UnexpectedEof;
        return switch (token) {
            .Ident => |ident| ident,
            else => return ParseError.UnexpectedToken,
        };
    }

    pub fn parseKeyword(self: *Parser, alloc: std.mem.Allocator, kw: Token.Keyword) !Token.Keyword {
        const token = try self.nextToken(alloc) orelse return ParseError.UnexpectedEof;
        defer token.deinit();
        return switch (token) {
            .Keyword => |tg| if (kw == tg) kw else ParseError.UnexpectedToken,
            else => return ParseError.UnexpectedToken,
        };
    }

    pub fn parsePunctuation(self: *Parser, alloc: std.mem.Allocator, punc: Token.Punctuation) !Token.Punctuation {
        const token = try self.nextToken(alloc) orelse return ParseError.UnexpectedEof;
        defer token.deinit();
        return switch (token) {
            .Punctuation => |tg| if (punc == tg) punc else ParseError.UnexpectedToken,
            else => return ParseError.UnexpectedToken,
        };
    }

    pub fn deinit(self: Parser) void {
        self.file.close();
    }

    fn skipWhitespace(self: *Parser) !?u8 {
        while (true) {
            const c = self.reader.readByte() catch |e| {
                if (e == error.EndOfStream) return null;
                return e;
            };
            if (!std.ascii.isWhitespace(c)) return c;
        }
    }
};