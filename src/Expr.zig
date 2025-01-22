const std = @import("std");
const dbg_print = std.debug.print;
const alloc_print = std.fmt.allocPrint;
const Token = @import("Token.zig");
const Literal = Token.Literal;
const parseNumber = Token.parseNumber;

pub const ExprType = enum {
    assign,
    binary,
    call,
    get,
    grouping,
    literal,
    logical,
    set,
    super,
    this,
    unary,
    variable,
};

pub const Expr = union(ExprType) {
    assign: struct {
        name: Token,
        value: *const Expr,
    },

    binary: struct {
        left: *const Expr,
        operator: Token,
        right: *const Expr,
    },

    call: struct {
        callee: *const Expr,
        paren: Token,
        arguments: []*const Expr,
    },

    get: struct {
        object: *const Expr,
        name: Token,
    },

    grouping: struct {
        expr: *const Expr,
    },

    literal: Literal,

    logical: struct {
        left: *const Expr,
        operator: Token,
        right: *const Expr,
    },

    set: struct {
        object: *const Expr,
        name: Token,
        value: *const Expr,
    },

    super: struct {
        keyword: Token,
        method: Token,
    },

    this: struct {
        keyword: Token,
    },

    unary: struct {
        operator: enum(u8) {
            Minus = '-',
            Bang = '!',

            fn slice(self: @This(), alloc: std.mem.Allocator) ![]const u8 {
                const fmt_str = try alloc_print(alloc, "{c}", .{@intFromEnum(self)});
                defer alloc.free(fmt_str);

                const str = try alloc.alloc(u8, fmt_str.len);
                @memcpy(str, fmt_str);

                return str;
            }
        },
        right: *const Expr,
    },

    variable: struct {
        name: Token,
    },

    pub fn slice(self: @This(), alloc: std.mem.Allocator) ![]const u8 {
        switch (self) {
            .assign => |assign| {
                const fmt_str = blk: {
                    const name = try assign.name.literal.slice(alloc);
                    const value = try assign.value.slice(alloc);
                    defer {
                        alloc.free(name);
                        alloc.free(value);
                    }

                    break :blk try alloc_print(
                        alloc,
                        "({s} {s})",
                        .{ name, value },
                    );
                };
                defer alloc.free(fmt_str);

                const str = try alloc.alloc(u8, fmt_str.len);
                @memcpy(str, fmt_str);

                return str;
            },
            .binary => |binary| {
                const fmt_str = blk: {
                    const left = try binary.left.slice(alloc);
                    const right = try binary.right.slice(alloc);
                    defer {
                        alloc.free(left);
                        alloc.free(right);
                    }

                    break :blk try alloc_print(
                        alloc,
                        "({s} {s} {s})",
                        .{ binary.operator.lexeme, left, right },
                    );
                };
                defer alloc.free(fmt_str);

                const str = try alloc.alloc(u8, fmt_str.len);
                @memcpy(str, fmt_str);

                return str;
            },
            .call => return "Call",
            .get => return "Get",
            .grouping => |group| {
                const fmt_str = blk: {
                    const grp = try group.expr.slice(alloc);
                    defer alloc.free(grp);

                    break :blk try alloc_print(
                        alloc,
                        "({s} {s})",
                        .{ "group", grp },
                    );
                };
                defer alloc.free(fmt_str);

                const str = try alloc.alloc(u8, fmt_str.len);
                @memcpy(str, fmt_str);

                return str;
            },
            .literal => |literal| {
                const fmt_str = blk: {
                    const ltr = try literal.slice(alloc);
                    defer alloc.free(ltr);

                    break :blk try alloc_print(
                        alloc,
                        "{s}",
                        .{ltr},
                    );
                };
                defer alloc.free(fmt_str);

                const str = try alloc.alloc(u8, fmt_str.len);
                @memcpy(str, fmt_str);

                return str;
            },
            .logical => return "Logical",
            .set => return "Set",
            .super => return "Super",
            .this => return "This",
            .unary => |unary| {
                const fmt_str = blk: {
                    const operator = try unary.operator.slice(alloc);
                    const right = try unary.right.slice(alloc);
                    defer {
                        alloc.free(operator);
                        alloc.free(right);
                    }

                    break :blk try alloc_print(
                        alloc,
                        "({s} {s})",
                        .{ operator, right },
                    );
                };
                defer alloc.free(fmt_str);

                const str = try alloc.alloc(u8, fmt_str.len);
                @memcpy(str, fmt_str);

                return str;
            },
            .variable => return "Variable",
        }
        return "";
    }
};

test "printing an expression" {
    const T = @import("Token.zig");
    const TT = T.Type;
    const E = Expr;
    const e: E = .{
        .binary = .{
            .left = &.{
                .unary = .{
                    .operator = .Minus,
                    .right = &E{ .literal = Literal.init(.number, "123") },
                },
            },
            .operator = T.init(TT.STAR, "*", Literal.init(.none, null), 1),
            .right = &E{
                .grouping = .{
                    .expr = &E{
                        .literal = Literal.init(.number, "123"),
                    },
                },
            },
        },
    };
    const expr_slc = try e.slice(std.testing.allocator);
    dbg_print("{s}\n", .{expr_slc});
    std.testing.allocator.free(expr_slc);
}
