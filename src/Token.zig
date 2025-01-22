const std = @import("std");
const dbg_print = std.debug.print;
const alloc_print = std.fmt.allocPrint;
const page_alloc = std.heap.page_allocator;
const stdout_writer = std.io.getStdOut().writer();

const Self = @This();
type: Type,
lexeme: []const u8,
literal: Literal,
line: usize,

pub const TokenList = std.ArrayList(Self);
pub const Type = enum {
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

pub const LiteralType = enum {
    string,
    number,
    bool,
    none,
};

pub const Literal = union(LiteralType) {
    string: []const u8,
    number: f64,
    bool: bool,
    none,

    pub fn init(ltype: LiteralType, literal: ?[]const u8) Literal {
        switch (ltype) {
            .number => {
                if (literal) |n| {
                    return Literal{ .number = parseNumber(n) };
                }
            },
            .string => {
                if (literal) |s| {
                    return Literal{ .string = s };
                }
            },
            .bool => {
                if (literal) |b| {
                    if (std.mem.eql(u8, b, "true")) {
                        return Literal{ .bool = true };
                    } else {
                        return Literal{ .bool = false };
                    }
                }
            },
            else => {
                return Literal.none;
            },
        }
        return Literal.none;
    }

    pub fn slice(self: Literal, alloc: std.mem.Allocator) ![]const u8 {
        switch (self) {
            .number => |n| {
                if (@ceil(n) == n) {
                    return try alloc_print(alloc, "{d}.0", .{n});
                }
                return try alloc_print(alloc, "{d}", .{n});
            },
            .string => |s| return s,
            .bool => |b| {
                if (b) {
                    return try alloc_print(alloc, "true", .{});
                } else {
                    return try alloc_print(alloc, "false", .{});
                }
            },
            .none => return "null",
        }
    }
};

pub fn init(ttype: Type, lexeme: []const u8, literal: Literal, line: usize) Self {
    return Self{
        .type = ttype,
        .lexeme = lexeme,
        .literal = literal,
        .line = line,
    };
}

pub fn parseNumber(num: []const u8) f64 {
    return std.fmt.parseFloat(f64, num) catch {
        const int = std.fmt.parseInt(isize, num, 10) catch {
            std.process.exit(1);
        };
        return @floatFromInt(int);
    };
}

pub fn print(self: Self) void {
    stdout_writer.print("{s} ", .{@tagName(self.type)}) catch |err| {
        dbg_print("Failed to print to stdout with err: \n{any}\n", .{err});
        std.process.exit(1);
    };
    switch (self.type) {
        .STRING => {
            const literal_slc = self.literal.slice(page_alloc) catch |err| {
                dbg_print("Failed to create slice from literal with error: \n{any}\n", .{err});
                std.process.exit(1);
            };
            stdout_writer.print("\"{s}\" {s}", .{ self.lexeme, literal_slc }) catch |err| {
                dbg_print("Failed to print to stdout with err: \n{any}\n", .{err});
                std.process.exit(1);
            };
        },

        else => {
            const literal_slc = self.literal.slice(page_alloc) catch |err| {
                dbg_print("Failed to create slice from literal with error: \n{any}\n", .{err});
                std.process.exit(1);
            };
            stdout_writer.print("{s} {s}", .{ self.lexeme, literal_slc }) catch |err| {
                dbg_print("Failed to print to stdout with err: \n{any}\n", .{err});
                std.process.exit(1);
            };
        },
    }
    stdout_writer.print("\n", .{}) catch |err| {
        dbg_print("Failed to print to stdout with err: \n{any}\n", .{err});
        std.process.exit(1);
    };
}
