const std = @import("std");
const dbg_print = std.debug.print;
const page_alloc = std.heap.page_allocator;
const stdout_writer = std.io.getStdOut().writer();

const Self = @This();
type: TokenType,
lexeme: []const u8,
literal: Literal,
line: usize,

pub const TokenList = std.ArrayList(Self);
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

pub fn New(ttype: TokenType, lexeme: []const u8, literal: Literal, line: usize) Self {
    return Self{
        .type = ttype,
        .lexeme = lexeme,
        .literal = literal,
        .line = line,
    };
}

fn parseNumber(num: []const u8) f64 {
    return std.fmt.parseFloat(f64, num) catch {
        const int = std.fmt.parseInt(isize, num, 10) catch {
            std.process.exit(1);
        };
        return @floatFromInt(int);
    };
}

pub fn print(self: Self) !void {
    try stdout_writer.print("{s} ", .{@tagName(self.type)});
    switch (self.type) {
        .STRING => try stdout_writer.print("\"{s}\" {s}", .{ self.lexeme, self.literal.toString() }),
        else => try stdout_writer.print("{s} {s}", .{ self.lexeme, self.literal.toString() }),
    }
    try stdout_writer.print("\n", .{});
}
