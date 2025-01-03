const std = @import("std");
// const Scanner = @import("Scanner.zig");
const dbg_print = std.debug.print;
const stdout_writer = std.io.getStdOut().writer(); // Placeholder, remove this line when implementing the scanner
const stderr_writer = std.io.getStdErr().writer(); // Placeholder, remove this line when implementing the scanner
const page_alloc = std.heap.page_allocator;

var command = std.ArrayList(u8).init(page_alloc);
var filename = std.ArrayList(u8).init(page_alloc);

const valid_commands = [_][]const u8{"tokenize"};

fn isValidCommand(needle: []u8) bool {
    for (valid_commands) |cmd| {
        if (std.mem.eql(u8, cmd, needle)) return true;
    }
    return false;
}

fn init() !void {
    // You can use print statements as follows for debugging, they'll be visible when running tests.
    dbg_print("Logs from your program will appear here!\n", .{});

    const args = try std.process.argsAlloc(page_alloc);
    defer std.process.argsFree(page_alloc, args);

    if (args.len < 3) {
        dbg_print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }
    try command.appendSlice(args[1]);
    try filename.appendSlice(args[2]);

    const cmd_slc = try command.toOwnedSlice();
    defer page_alloc.free(cmd_slc);
    if (!isValidCommand(cmd_slc)) {
        dbg_print("Unknown command: {s}\n", .{cmd_slc});
        std.process.exit(1);
    }
}

pub fn main() !void {
    try init();
    const file = try filename.toOwnedSlice();
    defer page_alloc.free(file);

    const file_contents = try std.fs.cwd().readFileAlloc(page_alloc, file, std.math.maxInt(usize));
    defer page_alloc.free(file_contents);

    var scanner = Scanner.New(file_contents);
    _ = try scanner.scan();
    try scanner.print();
}

// token
const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: Literal,
    line: usize,

    pub fn New(ttype: TokenType, lexeme: []const u8, literal: Literal, line: usize) Token {
        return Token{
            .type = ttype,
            .lexeme = lexeme,
            .literal = literal,
            .line = line,
        };
    }
    pub fn print(self: Token) !void {
        try stdout_writer.print("{s} ", .{@tagName(self.type)});
        switch (self.type) {
            .STRING => try stdout_writer.print("\"{s}\" {s}", .{ self.lexeme, self.literal.toString() }),
            else => try stdout_writer.print("{s} {s}", .{ self.lexeme, self.literal.toString() }),
        }
        try stdout_writer.print("\n", .{});
    }
};

pub const TokenList = std.ArrayList(Token);
pub const TokenType = enum {
    // Single-character tokens.
    COMMA,
    DOT,
    LEFT_BRACE,
    LEFT_PAREN,
    MINUS,
    PLUS,
    RIGHT_BRACE,
    RIGHT_PAREN,
    SEMICOLON,
    SLASH,
    STAR,

    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals.
    IDENTIFIER,
    NUMBER,
    STRING,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    EOF,
    FALSE,
    FOR,
    FUN,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,
};

pub const Literal = union(enum) {
    number: f64,
    string: []const u8,
    none,

    pub fn toString(self: Literal) []const u8 {
        switch (self) {
            .number => |n| {
                if (@ceil(n) == n) {
                    return std.fmt.allocPrint(page_alloc, "{d}.0", .{n}) catch "";
                }
                return std.fmt.allocPrint(page_alloc, "{d}", .{n}) catch "";
            },
            .string => |s| return s,
            .none => return "null",
        }
    }

    pub fn Number(num: []const u8) Literal {
        return Literal{ .number = parseNumber(num) };
    }
    pub fn String(str: []const u8) Literal {
        return Literal{ .string = str };
    }
    pub fn None() Literal {
        return Literal.none;
    }
};

fn parseNumber(num: []const u8) f64 {
    return std.fmt.parseFloat(f64, num) catch {
        const int = std.fmt.parseInt(isize, num, 10) catch {
            std.process.exit(1);
        };
        return @floatFromInt(int);
    };
}

// scanner
const alloc_print = std.fmt.allocPrint;
const ScannerError = error{UnexpectedError};

const Scanner = struct {
    icurr: usize,
    line: usize,
    skipChar: bool,
    skipNext: usize,
    source: []const u8,
    tokenList: TokenList,
    scanError: ?ScannerError,

    pub fn New(source: []const u8) Scanner {
        return Scanner{
            .icurr = 0,
            .line = 1,
            .skipChar = false,
            .skipNext = 0,
            .source = source,
            .tokenList = TokenList.init(page_alloc),
            .scanError = null,
        };
    }

    fn peek(self: Scanner, char: u8) bool {
        if (self.icurr < self.source.len - 1) {
            return char == self.source[self.icurr + 1];
        }
        return false;
    }

    pub fn print(self: Scanner) !void {
        for (self.tokenList.items) |token| {
            try token.print();
        }
        if (self.scanError) |err| {
            if (err == error.UnexpectedError) {
                std.process.exit(65);
            }
        }
    }

    pub fn scan(self: *Scanner) !void {
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
                                    break;
                                },
                                else => self.skipNext += 1,
                            }
                        }
                        continue;
                    }
                    try self.tokenList.append(Token.New(TokenType.SLASH, "/", Literal.None(), self.line));
                },
                // case char == SLASH.char1():
                // 	if COMMENT.char2() >= 0 && s.peek() == COMMENT.char2() {
                // 	SkipTillNL:
                // 		for _, r := range s.Source[iChar:] {
                // 			switch r {
                // 			case NEW_LINE.char1():
                // 				break SkipTillNL
                // 			default:
                // 				s.SkipNext++
                // 				break
                // 			}
                // 		}
                // 		continue
                // 	}
                // 	s.TokenList.append(Token{SLASH, SLASH.Literal, NULL, s.Line})
                // 	break
                else => {
                    try stderr_writer.print("[line {}] Error: Unexpected character: {c}\n", .{ self.line, char });
                    self.scanError = error.UnexpectedError;
                },
            }
        }
        try self.tokenList.append(Token.New(TokenType.EOF, "", Literal.None(), self.line));
    }
};
