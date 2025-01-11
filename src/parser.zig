//! Parser is recursive descent Lox parser that takes `TokenList` as input and generates an `Ast`.
///
/// * `expression`   → equality ;
/// * `equality`     → comparison ( ( `!=` | `==` ) comparison )* ;
/// * `comparison`   → term ( ( `>` | `>=` | `<` | `<=` ) term )* ;
/// * `term`         → factor ( ( `-` | `+` ) factor )* ;
/// * `factor`       → unary ( ( `/` | `*` ) unary )* ;
/// * `unary`        → ( `!` | `-` ) unary
///                    | primary ;
/// * `primary`      → NUMBER | STRING | `true` | `false` | `nil`
///                    | `(` expression `)` ;
const std = @import("std");
const dbg_print = std.debug.print;
const alloc_print = std.fmt.allocPrint;
const Token = @import("token.zig");
const TokenList = Token.TokenList;
const Expr = @import("expr.zig");

const Self = @This();

tokens: TokenList,
current: usize,

pub fn init(tokens: TokenList) Self {
    return Self{
        .tokens = tokens,
        .current = 0,
    };
}

pub fn deinit(self: *Self) void {
    self.tokens.deinit();
}

pub fn parse(self: Self) void {
    for (self.tokens.items) |token| {
        switch (token.type) {
            .EQUAL_EQUAL => {
                dbg_print("EQUAL_EQUAL\n", .{});
            },
            else => {},
        }
    }
}

// fn peekChar(self: Self) u8 {
//     if (self.icurr < self.source.len - 1) {
//         return self.source[self.icurr + 1];
//     }
//     return self.source[self.icurr];
// }
//
// pub fn peekCharAt(self: Self, idx: usize) u8 {
//     if (idx < self.source.len - 1) {
//         return self.source[idx + 1];
//     }
//     return self.source[idx];
// }
//
// /// return true if the next char matches the argument
// fn peekCharEql(self: Self, char: u8) bool {
//     if (self.icurr < self.source.len - 1) {
//         return char == self.source[self.icurr + 1];
//     }
//     return false;
// }
// fn match(self: Self, types: anytype) void {
//     for (types) |t| {
//         if (self.tokens
//     }
// }
//
// fn expression(_: Self) Expr {
//     return equality();
// }
// fn equality(_: Self) Expr {
//     const expr = comparison();
//     while (match(.{ Token.Type.BANG_EQUAL, Token.Type.EQUAL_EQUAL })) {
//         continue;
//     }
//     return expr;
// }
//
// fn comparison(_: Self) Expr {
//     const expr = term();
//     while (match(.{ Token.Type.GREATER, Token.Type.GREATER_EQUAL, Token.Type.LESS, Token.Type.LESS_EQUAL })) {
//         continue;
//     }
//     return expr;
// }
//
// fn term(_: Self) Expr {
//     const expr = factor();
//     while (match(.{ Token.Type.MINUS, Token.Type.PLUS })) {
//         continue;
//     }
//     return expr;
// }
//
// fn factor(_: Self) Expr {
//     const expr = unary();
//     while (match(.{ Token.Type.STAR, Token.Type.SLASH })) {
//         continue;
//     }
//     return expr;
// }
//
// fn unary(_: Self) Expr {
//     if (match(.{ Token.Type.STAR, Token.Type.SLASH })) {
//         _ = 1;
//     }
//     return primary();
// }
//
// fn primary(_: Self) Expr {
//     if (match(.{ Token.Type.STAR, Token.Type.SLASH })) {
//         _ = 1;
//     }
//     return primary();
// }

pub fn print(self: *Self) void {
    dbg_print("Parser.print()\n", .{});
    self.parse();
}
