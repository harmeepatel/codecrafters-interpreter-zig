const std = @import("std");
const Token = @import("token.zig");
const TokenType = Token.TokenType;
const TokenList = Token.TokenList;
const Literal = Token.Literal;
const dbg_print = std.debug.print;
const alloc_print = std.fmt.allocPrint;
const page_alloc = std.heap.page_allocator;

const stdout_writer = std.io.getStdOut().writer();
const stderr_writer = std.io.getStdErr().writer();

const ScannerError = error{
    UnexpectedCharacter,
    UnterminatedString,
};
const Self = @This();

icurr: usize,
line: usize,
skipChar: bool,
skipNext: usize,
source: []const u8,
tokenList: TokenList,
scanError: ?ScannerError,

pub fn New(source: []const u8) Self {
    return Self{
        .icurr = 0,
        .line = 1,
        .skipChar = false,
        .skipNext = 0,
        .source = source,
        .tokenList = TokenList.init(page_alloc),
        .scanError = null,
    };
}

fn peek(self: Self, char: u8) bool {
    if (self.icurr < self.source.len - 1) {
        return char == self.source[self.icurr + 1];
    }
    return false;
}

pub fn print(self: Self) !void {
    for (self.tokenList.items) |token| {
        try token.print();
    }
    if (self.scanError) |err| {
        if (err == ScannerError.UnexpectedCharacter or err == ScannerError.UnterminatedString) {
            std.process.exit(65);
        }
    }
}

pub fn scan(self: *Self) !void {
    CharLoop: for (self.source, 0..) |char, i| {
        self.icurr = i;
        if (self.skipChar) {
            self.skipChar = false;
            continue;
        }
        while (self.skipNext > 0) {
            self.skipNext -= 1;
            continue :CharLoop;
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
                if (self.peek('=')) {
                    try self.tokenList.append(Token.New(TokenType.EQUAL_EQUAL, "==", Literal.None(), self.line));
                    self.skipChar = true;
                    continue;
                }
                try self.tokenList.append(Token.New(TokenType.EQUAL, "=", Literal.None(), self.line));
            },
            '!' => {
                if (self.peek('=')) {
                    try self.tokenList.append(Token.New(TokenType.BANG_EQUAL, "!=", Literal.None(), self.line));
                    self.skipChar = true;
                    continue;
                }
                try self.tokenList.append(Token.New(TokenType.BANG, "!", Literal.None(), self.line));
            },
            '<' => {
                if (self.peek('=')) {
                    try self.tokenList.append(Token.New(TokenType.LESS_EQUAL, "<=", Literal.None(), self.line));
                    self.skipChar = true;
                    continue;
                }
                try self.tokenList.append(Token.New(TokenType.LESS, "<", Literal.None(), self.line));
            },
            '>' => {
                if (self.peek('=')) {
                    try self.tokenList.append(Token.New(TokenType.GREATER_EQUAL, ">=", Literal.None(), self.line));
                    self.skipChar = true;
                    continue;
                }
                try self.tokenList.append(Token.New(TokenType.GREATER, ">", Literal.None(), self.line));
            },
            '/' => {
                if (self.peek('/')) {
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
                const start: usize = self.icurr + 1;
                var end: usize = start;
                while (end < self.source.len) : (end += 1) {
                    const c = self.source[end];
                    self.skipNext += 1;
                    if (c == '\n') {
                        try stderr_writer.print("[line {}] Error: Unterminated string.\n", .{self.line});
                        self.scanError = error.UnterminatedString;
                        self.line += 1;
                        continue :CharLoop;
                    }
                    if (c == '"') {
                        break;
                    }
                }
                if (start >= self.source.len) {
                    try stderr_writer.print("[line {}] Error: Unterminated string.\n", .{self.line});
                    self.scanError = error.UnterminatedString;
                }
                try self.tokenList.append(Token.New(TokenType.STRING, self.source[start..end], Literal{ .string = self.source[start..end] }, self.line));
            },
            else => {
                try stderr_writer.print("[line {}] Error: Unexpected character: {c}\n", .{ self.line, char });
                self.scanError = error.UnexpectedCharacter;
            },
        }
    }
    try self.tokenList.append(Token.New(TokenType.EOF, "", Literal.None(), self.line));
}
