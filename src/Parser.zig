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
const Token = @import("Token.zig");
const TokenList = Token.TokenList;
const Expr = @import("Expr.zig").Expr;

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

const Self = @This();

alloc: std.mem.Allocator,
tokens: TokenList,
curr_idx: usize,
curr_token: Token,

pub const ParseError = error{};

pub fn init(tokens: TokenList, alloc: std.mem.Allocator) Self {
    return Self{
        .alloc = alloc,
        .tokens = tokens,
        .curr_idx = 0,
        .curr_token = tokens.items[0],
    };
}

pub fn deinit(self: *Self) void {
    self.tokens.deinit();
}

fn match(self: *Self, types: []Token.Type) bool {
    for (types) |t| {
        if (self.check(t)) {
            self.advance();
            return true;
        }
    }
    return false;
}

fn advance(self: *Self) Token {
    if (!self.isEnd()) {
        self.curr_idx += 1;
        self.curr_token = self.tokens.items[self.curr_idx];
    }
    return self.previous();
}

fn previous(self: Self) Token {
    if (self.curr_idx < 0) {
        @"error"(self.curr_token.line, "Index out of bound!", .{});
    }
    return self.tokens.items[self.curr_idx - 1];
}

fn check(self: Self, typ: Token.Type) bool {
    if (self.isEnd()) return false;
    return self.curr_token.type == typ;
}

fn isEnd(self: Self) bool {
    return self.curr_token.type == Token.Type.EOF;
}

fn expression(_: Self) Expr {
    return equality();
}

fn consume(self: *Self, typ: Token.Type, msg: []const u8) !Token {
    if (self.check(typ)) return self.advance();

    return self.err(self.curr_token, msg);
}

fn err(_: Self, token: Token, msg: []const u8) ParseError {
    error.ParserError{ .location = token, .msg = msg };
}

fn equality(self: Self) Expr {
    var expr = self.comparison();
    var match_tokens = [_]Token.Type{ .EQUAL_EQUAL, .BANG_EQUAL };
    while (self.match(&match_tokens)) {
        const operator = self.previous();
        const right = self.comparison();
        expr = .{
            .binary = .{
                .left = &expr,
                .operator = operator,
                .right = &right,
            },
        };
    }
    return expr;
}

fn comparison(self: Self) Expr {
    var expr = self.term();
    var match_tokens = [_]Token.Type{ Token.Type.GREATER, Token.Type.GREATER_EQUAL, Token.Type.LESS, Token.Type.LESS_EQUAL };
    while (self.match(&match_tokens)) {
        const operator = self.previous();
        const right = self.term();
        expr = .{
            .binary = .{
                .left = expr,
                .operator = operator,
                .right = right,
            },
        };
    }
    return expr;
}

fn term(self: Self) Expr {
    const expr = self.factor();
    var match_tokens = [_]Token.Type{ Token.Type.MINUS, Token.Type.PLUS };
    while (self.match(&match_tokens)) {
        const operator = self.previous();
        const right = self.factor();
        expr = .{
            .binary = .{
                .left = expr,
                .operator = operator,
                .right = right,
            },
        };
    }
    return expr;
}

fn factor(self: Self) Expr {
    const expr = self.unary();
    var match_tokens = [_]Token.Type{ Token.Type.STAR, Token.Type.SLASH };
    while (self.match(&match_tokens)) {
        const operator = self.previous();
        const right = self.factor();
        expr = .{
            .binary = .{
                .left = expr,
                .operator = operator,
                .right = right,
            },
        };
    }
    return expr;
}

fn unary(self: Self) Expr {
    var match_tokens = [_]Token.Type{ Token.Type.BANG, Token.Type.MINUS };
    if (self.match(&match_tokens)) {
        const operator = self.previous();
        const right = self.primary();
        return Expr{
            .unary = .{
                .operator = operator,
                .right = right,
            },
        };
    }
    return self.primary();
}

fn primary(self: Self) Expr {
    if (self.match(Token.Type.FALSE)) return Expr{ .literal = .{ .bool = false } };
    if (self.match(Token.Type.TRUE)) return Expr{ .literal = .{ .bool = true } };
    if (self.match(Token.Type.NIL)) return Expr{ .literal = .{.none} };

    var string_or_number = [_]Token.Type{ Token.Type.NUMBER, Token.Type.STRING };
    if (self.match(&string_or_number)) {
        return Expr{ .literal = .{self.previous().literal} };
    }

    var left_paren = [_]Token.Type{Token.Type.LEFT_PAREN};
    if (match(&left_paren)) {
        const expr = self.expression();
        self.consume(Token.Type.RIGHT_PAREN, "Exprct ')' after expression.");
        return Expr{ .grouping = .{ .expr = expr } };
    }
}

pub fn print(self: *Self) void {
    dbg_print("--- parser.print() ---\n", .{});
    _ = self;
    // self.parse();
}
