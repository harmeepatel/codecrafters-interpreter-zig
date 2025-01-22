//! Scans and tokenizes the source for the `parser`.
const std = @import("std");
const builtin = @import("builtin");
const Token = @import("Token.zig");
const TokenList = Token.TokenList;
const dbg_print = std.debug.print;

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
    PeekOutOfBounds,
};
const Self = @This();

curr_idx: usize,
line: usize,
scan_error: ?ScannerError,
skip_char: bool,
skip_next: usize,
source: []const u8,
token_list: TokenList,

/// Generate new scanner.
/// takes source as `[]const u8` and an allocator to manage the `TokenList`.
pub fn init(source: []const u8, alloc: std.mem.Allocator) Self {
    return Self{
        .curr_idx = 0,
        .line = 1,
        .scan_error = null,
        .skip_char = false,
        .skip_next = 0,
        .source = source,
        .token_list = TokenList.init(alloc),
    };
}

pub fn deinit(self: Self) void {
    self.token_list.deinit();
}

fn skipTillWhiteSpace(self: *Self, from: usize) void {
    for (self.source[from..]) |c| {
        if (c == ' ' or c == '\n' or c == '\t') {
            break;
        }
        self.skip_next += 1;
    }
}

/// Return next char from current.
fn peekChar(self: Self) ?u8 {
    if (self.curr_idx < self.source.len - 1) {
        return self.source[self.curr_idx + 1];
    }
    return null;
}
/// Return next char from `idx`.
pub fn peekCharAt(self: Self, idx: usize) ?u8 {
    if (idx < self.source.len - 1) {
        return self.source[idx + 1];
    }
    return null;
}
/// Return true if the next char matches the argument
/// Here peek is different from the one implemented in crafting interpreters. It peeks the next char
/// instead of taking a peek at the current char.
fn peekCharEql(self: Self, char: u8) bool {
    if (self.curr_idx < self.source.len - 1) {
        return char == self.source[self.curr_idx + 1];
    }
    return false;
}

pub fn print(self: Self) void {
    for (self.token_list.items) |token| {
        token.print();
    }
    if (self.scan_error) |_| {
        std.process.exit(65);
    }
}

pub fn tokenize(self: *Self) !void {
    ScanLoop: for (self.source, 0..) |char, icurr| {
        self.curr_idx = icurr;
        if (self.skip_char) {
            self.skip_char = false;
            continue :ScanLoop;
        }
        while (self.skip_next > 0) {
            self.skip_next -= 1;
            continue :ScanLoop;
        }
        switch (char) {
            '\n' => self.line += 1,
            '(' => try self.token_list.append(Token.init(Token.Type.LEFT_PAREN, "(", Token.Literal.init(.none, null), self.line)),
            ')' => try self.token_list.append(Token.init(Token.Type.RIGHT_PAREN, ")", Token.Literal.init(.none, null), self.line)),
            '{' => try self.token_list.append(Token.init(Token.Type.LEFT_BRACE, "{", Token.Literal.init(.none, null), self.line)),
            '}' => try self.token_list.append(Token.init(Token.Type.RIGHT_BRACE, "}", Token.Literal.init(.none, null), self.line)),
            ',' => try self.token_list.append(Token.init(Token.Type.COMMA, ",", Token.Literal.init(.none, null), self.line)),
            '.' => try self.token_list.append(Token.init(Token.Type.DOT, ".", Token.Literal.init(.none, null), self.line)),
            '-' => try self.token_list.append(Token.init(Token.Type.MINUS, "-", Token.Literal.init(.none, null), self.line)),
            '+' => try self.token_list.append(Token.init(Token.Type.PLUS, "+", Token.Literal.init(.none, null), self.line)),
            ';' => try self.token_list.append(Token.init(Token.Type.SEMICOLON, ";", Token.Literal.init(.none, null), self.line)),
            '*' => try self.token_list.append(Token.init(Token.Type.STAR, "*", Token.Literal.init(.none, null), self.line)),
            '\t', ' ' => {},

            '=' => {
                if (self.peekCharEql('=')) {
                    try self.token_list.append(Token.init(Token.Type.EQUAL_EQUAL, "==", Token.Literal.init(.none, null), self.line));
                    self.skip_char = true;
                    continue;
                }
                try self.token_list.append(Token.init(Token.Type.EQUAL, "=", Token.Literal.init(.none, null), self.line));
            },

            '!' => {
                if (self.peekCharEql('=')) {
                    try self.token_list.append(Token.init(Token.Type.BANG_EQUAL, "!=", Token.Literal.init(.none, null), self.line));
                    self.skip_char = true;
                    continue;
                }
                try self.token_list.append(Token.init(Token.Type.BANG, "!", Token.Literal.init(.none, null), self.line));
            },

            '<' => {
                if (self.peekCharEql('=')) {
                    try self.token_list.append(Token.init(Token.Type.LESS_EQUAL, "<=", Token.Literal.init(.none, null), self.line));
                    self.skip_char = true;
                    continue;
                }
                try self.token_list.append(Token.init(Token.Type.LESS, "<", Token.Literal.init(.none, null), self.line));
            },

            '>' => {
                if (self.peekCharEql('=')) {
                    try self.token_list.append(Token.init(Token.Type.GREATER_EQUAL, ">=", Token.Literal.init(.none, null), self.line));
                    self.skip_char = true;
                    continue;
                }
                try self.token_list.append(Token.init(Token.Type.GREATER, ">", Token.Literal.init(.none, null), self.line));
            },

            '/' => {
                if (self.peekCharEql('/')) {
                    for (self.source[self.curr_idx..]) |c| {
                        switch (c) {
                            '\n' => {
                                self.line += 1;
                                break;
                            },
                            else => self.skip_next += 1,
                        }
                    }
                    continue;
                }
                try self.token_list.append(Token.init(Token.Type.SLASH, "/", Token.Literal.init(.none, null), self.line));
            },

            '"' => {
                self.skip_next += 1;
                var end: usize = self.curr_idx + 1;
                while (end < self.source.len - 1 and self.source[end] != '"') : (end += 1) {
                    self.skip_next += 1;
                }
                if (end >= self.source.len - 1 and self.source[end] != '"') {
                    @"error"(self.line, "Unterminated string.", .{});
                    self.scan_error = error.UnterminatedString;
                    continue :ScanLoop;
                }
                try self.token_list.append(Token.init(
                    Token.Type.STRING,
                    self.source[self.curr_idx + 1 .. end],
                    Token.Literal.init(.string, self.source[self.curr_idx + 1 .. end]),
                    self.line,
                ));
            },

            '0'...'9' => {
                var end = self.curr_idx + 1;
                var decimal_encountered = false;
                for (self.source[self.curr_idx + 1 ..]) |c| {
                    switch (c) {
                        '0'...'9' => {
                            end += 1;
                            self.skip_next += 1;
                        },
                        '.' => {
                            if (!std.ascii.isDigit(self.peekCharAt(end).?)) {
                                end += 1;
                                self.skipTillWhiteSpace(end);
                                continue :ScanLoop;
                            }
                            decimal_encountered = true;
                            end += 1;
                            self.skip_next += 1;
                        },
                        else => {
                            break;
                        },
                    }
                }
                try self.token_list.append(Token.init(
                    Token.Type.NUMBER,
                    self.source[self.curr_idx..end],
                    Token.Literal.init(.number, self.source[self.curr_idx..end]),
                    self.line,
                ));
            },

            'a'...'z', 'A'...'Z', '_' => {
                var end = self.curr_idx + 1;
                for (self.source[self.curr_idx + 1 ..]) |c| {
                    switch (c) {
                        'a'...'z', 'A'...'Z', '_', '0'...'9' => {
                            end += 1;
                            self.skip_next += 1;
                        },
                        else => {
                            break;
                        },
                    }
                }
                const ident = self.source[self.curr_idx..end];
                if (std.mem.eql(u8, ident, "and")) {
                    try self.token_list.append(Token.init(
                        Token.Type.AND,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "class")) {
                    try self.token_list.append(Token.init(
                        Token.Type.CLASS,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "else")) {
                    try self.token_list.append(Token.init(
                        Token.Type.ELSE,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "eof")) {
                    try self.token_list.append(Token.init(
                        Token.Type.EOF,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "false")) {
                    try self.token_list.append(Token.init(
                        Token.Type.FALSE,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "for")) {
                    try self.token_list.append(Token.init(
                        Token.Type.FOR,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "fun")) {
                    try self.token_list.append(Token.init(
                        Token.Type.FUN,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "if")) {
                    try self.token_list.append(Token.init(
                        Token.Type.IF,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "nil")) {
                    try self.token_list.append(Token.init(
                        Token.Type.NIL,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "or")) {
                    try self.token_list.append(Token.init(
                        Token.Type.OR,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "print")) {
                    try self.token_list.append(Token.init(
                        Token.Type.PRINT,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "return")) {
                    try self.token_list.append(Token.init(
                        Token.Type.RETURN,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "super")) {
                    try self.token_list.append(Token.init(
                        Token.Type.SUPER,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "this")) {
                    try self.token_list.append(Token.init(
                        Token.Type.THIS,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "true")) {
                    try self.token_list.append(Token.init(
                        Token.Type.TRUE,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "var")) {
                    try self.token_list.append(Token.init(
                        Token.Type.VAR,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else if (std.mem.eql(u8, ident, "while")) {
                    try self.token_list.append(Token.init(
                        Token.Type.WHILE,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                } else {
                    try self.token_list.append(Token.init(
                        Token.Type.IDENTIFIER,
                        ident,
                        Token.Literal.init(.none, null),
                        self.line,
                    ));
                }
            },

            else => {
                @"error"(self.line, "Unexpected character: {c}", .{char});
                self.scan_error = error.UnexpectedCharacter;
            },
        }
    }
    try self.token_list.append(Token.init(Token.Type.EOF, "", Token.Literal.init(.none, null), self.line));
}
