const std = @import("std");
const builtin = @import("builtin");
const Token = @import("token.zig");
const TokenType = Token.TokenType;
const TokenList = Token.TokenList;
const Literal = Token.Literal;
const dbg_print = std.debug.print;
const alloc_print = std.fmt.allocPrint;

const stdout_writer = std.io.getStdOut().writer();
const stderr_writer = std.io.getStdErr().writer();

fn @"error"(line_num: usize, comptime msg: []const u8, args: anytype) void {
    stderr_writer.print("[line {}] Error: ", .{line_num}) catch {
        dbg_print("error printing to stderr_writer.\n", .{});
    };
    stderr_writer.print(msg ++ "\n", args) catch {
        dbg_print("error printing to stderr_writer.\n", .{});
    };
}

const ScannerError = error{
    UnexpectedCharacter,
    UnterminatedString,
};
const Self = @This();

allocator: std.mem.Allocator,
icurr: usize,
line: usize,
scanError: ?ScannerError,
skipChar: bool,
skipNext: usize,
source: []const u8,
tokenList: TokenList,

pub fn New(source: []const u8, alloc: std.mem.Allocator) Self {
    return Self{
        .allocator = alloc,
        .icurr = 0,
        .line = 1,
        .scanError = null,
        .skipChar = false,
        .skipNext = 0,
        .source = source,
        .tokenList = TokenList.init(alloc),
    };
}

pub fn deinit(self: Self) void {
    self.tokenList.deinit();
}

fn skipTillWhiteSpace(self: *Self, from: usize) void {
    for (self.source[from..]) |c| {
        if (c == ' ' or c == '\n' or c == '\t') {
            break;
        }
        self.skipNext += 1;
    }
}

fn peek(self: Self) u8 {
    if (self.icurr < self.source.len - 1) {
        return self.source[self.icurr + 1];
    }
    return self.source[self.icurr];
}
fn peekAt(self: Self, idx: usize) u8 {
    if (idx < self.source.len - 1) {
        return self.source[idx + 1];
    }
    return self.source[idx];
}
fn peekEql(self: Self, char: u8) bool {
    if (self.icurr < self.source.len - 1) {
        return char == self.source[self.icurr + 1];
    }
    return false;
}

pub fn print(self: Self) !void {
    for (self.tokenList.items) |token| {
        try token.print();
    }
    if (self.scanError) |_| {
        std.process.exit(65);
    }
}

pub fn scan(self: *Self) !void {
    ScanLoop: for (self.source, 0..) |char, icurr| {
        self.icurr = icurr;
        if (self.skipChar) {
            self.skipChar = false;
            continue :ScanLoop;
        }
        while (self.skipNext > 0) {
            self.skipNext -= 1;
            continue :ScanLoop;
        }
        switch (char) {
            '\n' => self.line += 1,
            '(' => try self.tokenList.append(Token.New(TokenType.LEFT_PAREN, "(", Literal.None(), self.line)),
            ')' => try self.tokenList.append(Token.New(TokenType.RIGHT_PAREN, ")", Literal.None(), self.line)),
            '{' => try self.tokenList.append(Token.New(TokenType.LEFT_BRACE, "{", Literal.None(), self.line)),
            '}' => try self.tokenList.append(Token.New(TokenType.RIGHT_BRACE, "}", Literal.None(), self.line)),
            ',' => try self.tokenList.append(Token.New(TokenType.COMMA, ",", Literal.None(), self.line)),
            '.' => try self.tokenList.append(Token.New(TokenType.DOT, ".", Literal.None(), self.line)),
            '-' => try self.tokenList.append(Token.New(TokenType.MINUS, "-", Literal.None(), self.line)),
            '+' => try self.tokenList.append(Token.New(TokenType.PLUS, "+", Literal.None(), self.line)),
            ';' => try self.tokenList.append(Token.New(TokenType.SEMICOLON, ";", Literal.None(), self.line)),
            '*' => try self.tokenList.append(Token.New(TokenType.STAR, "*", Literal.None(), self.line)),
            '\t', ' ' => {},

            '=' => {
                if (self.peekEql('=')) {
                    try self.tokenList.append(Token.New(TokenType.EQUAL_EQUAL, "==", Literal.None(), self.line));
                    self.skipChar = true;
                    continue;
                }
                try self.tokenList.append(Token.New(TokenType.EQUAL, "=", Literal.None(), self.line));
            },

            '!' => {
                if (self.peekEql('=')) {
                    try self.tokenList.append(Token.New(TokenType.BANG_EQUAL, "!=", Literal.None(), self.line));
                    self.skipChar = true;
                    continue;
                }
                try self.tokenList.append(Token.New(TokenType.BANG, "!", Literal.None(), self.line));
            },

            '<' => {
                if (self.peekEql('=')) {
                    try self.tokenList.append(Token.New(TokenType.LESS_EQUAL, "<=", Literal.None(), self.line));
                    self.skipChar = true;
                    continue;
                }
                try self.tokenList.append(Token.New(TokenType.LESS, "<", Literal.None(), self.line));
            },

            '>' => {
                if (self.peekEql('=')) {
                    try self.tokenList.append(Token.New(TokenType.GREATER_EQUAL, ">=", Literal.None(), self.line));
                    self.skipChar = true;
                    continue;
                }
                try self.tokenList.append(Token.New(TokenType.GREATER, ">", Literal.None(), self.line));
            },

            '/' => {
                if (self.peekEql('/')) {
                    for (self.source[self.icurr..]) |c| {
                        switch (c) {
                            '\n' => {
                                self.line += 1;
                                break;
                            },
                            else => self.skipNext += 1,
                        }
                    }
                    continue;
                }
                try self.tokenList.append(Token.New(TokenType.SLASH, "/", Literal.None(), self.line));
            },

            '"' => {
                self.skipNext += 1;
                var end: usize = self.icurr + 1;
                while (end < self.source.len - 1 and self.source[end] != '"') : (end += 1) {
                    self.skipNext += 1;
                }
                if (end >= self.source.len - 1 and self.source[end] != '"') {
                    @"error"(self.line, "Unterminated string.", .{});
                    self.scanError = error.UnterminatedString;
                    continue :ScanLoop;
                }
                try self.tokenList.append(Token.New(
                    TokenType.STRING,
                    self.source[self.icurr + 1 .. end],
                    Literal.String(self.source[self.icurr + 1 .. end]),
                    self.line,
                ));
            },

            '0'...'9' => {
                var end = self.icurr + 1;
                var decimal_encountered = false;
                for (self.source[self.icurr + 1 ..]) |c| {
                    switch (c) {
                        '0'...'9' => {
                            end += 1;
                            self.skipNext += 1;
                        },
                        '.' => {
                            if (!std.ascii.isDigit(self.peekAt(end))) {
                                end += 1;
                                self.skipTillWhiteSpace(end);
                                continue :ScanLoop;
                            }
                            decimal_encountered = true;
                            end += 1;
                            self.skipNext += 1;
                        },
                        else => {
                            break;
                        },
                    }
                }
                try self.tokenList.append(Token.New(
                    TokenType.NUMBER,
                    self.source[self.icurr..end],
                    Literal.Number(self.source[self.icurr..end]),
                    self.line,
                ));
            },

            'a'...'z', 'A'...'Z', '_' => {
                var end = self.icurr + 1;
                for (self.source[self.icurr + 1 ..]) |c| {
                    switch (c) {
                        'a'...'z', 'A'...'Z', '_', '0'...'9' => {
                            end += 1;
                            self.skipNext += 1;
                        },
                        else => {
                            break;
                        },
                    }
                }
                const ident = self.source[self.icurr..end];
                if (std.mem.eql(u8, ident, "and")) {
                    try self.tokenList.append(Token.New(
                        TokenType.AND,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "class")) {
                    try self.tokenList.append(Token.New(
                        TokenType.CLASS,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "else")) {
                    try self.tokenList.append(Token.New(
                        TokenType.ELSE,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "eof")) {
                    try self.tokenList.append(Token.New(
                        TokenType.EOF,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "false")) {
                    try self.tokenList.append(Token.New(
                        TokenType.FALSE,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "for")) {
                    try self.tokenList.append(Token.New(
                        TokenType.FOR,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "fun")) {
                    try self.tokenList.append(Token.New(
                        TokenType.FUN,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "if")) {
                    try self.tokenList.append(Token.New(
                        TokenType.IF,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "nil")) {
                    try self.tokenList.append(Token.New(
                        TokenType.NIL,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "or")) {
                    try self.tokenList.append(Token.New(
                        TokenType.OR,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "print")) {
                    try self.tokenList.append(Token.New(
                        TokenType.PRINT,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "return")) {
                    try self.tokenList.append(Token.New(
                        TokenType.RETURN,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "super")) {
                    try self.tokenList.append(Token.New(
                        TokenType.SUPER,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "this")) {
                    try self.tokenList.append(Token.New(
                        TokenType.THIS,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "true")) {
                    try self.tokenList.append(Token.New(
                        TokenType.TRUE,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "var")) {
                    try self.tokenList.append(Token.New(
                        TokenType.VAR,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "while")) {
                    try self.tokenList.append(Token.New(
                        TokenType.WHILE,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                } else {
                    try self.tokenList.append(Token.New(
                        TokenType.IDENTIFIER,
                        ident,
                        Literal.None(),
                        self.line,
                    ));
                }
            },

            else => {
                @"error"(self.line, "Unexpected character: {c}", .{char});
                self.scanError = error.UnexpectedCharacter;
            },
        }
    }
    try self.tokenList.append(Token.New(TokenType.EOF, "", Literal.None(), self.line));
}
