const std = @import("std");
const dbg_print = std.debug.print;
const alloc_print = std.fmt.allocPrint;
const Token = @import("token.zig");
const parseNumber = Token.parseNumber;

const page_alloc = std.heap.page_allocator;

pub const Assign = struct {
    name: Token,
    value: *const Expr,
};

pub const Binary = struct {
    left: *const Expr,
    operator: Token,
    right: *const Expr,
};

pub const Call = struct {
    callee: *const Expr,
    paren: Token,
    arguments: []*const Expr,
};

pub const Get = struct {
    object: *const Expr,
    name: Token,
};

pub const Grouping = struct {
    expr: *const Expr,
};

// pub const LiteralType = enum {
//     str,
//     num,
//     bool,
//     none,
// };
//
// pub const Literal = union(LiteralType) {
//     str: []const u8,
//     num: f64,
//     bool: bool,
//     none,
//
//     pub fn string(self: Literal) []const u8 {
//         switch (self) {
//             .num => |n| {
//                 if (@ceil(n) == n) {
//                     return alloc_print(ally, "{d}.0", .{n}) catch |err| {
//                         dbg_print("failed to alloc_print with err: \n{any}\n", .{err});
//                         std.process.exit(1);
//                     };
//                 }
//                 return alloc_print(ally, "{d}", .{n}) catch |err| {
//                     dbg_print("failed to alloc_print with err: \n{any}\n", .{err});
//                     std.process.exit(1);
//                 };
//             },
//             .str => |s| return s,
//             .bool => |b| {
//                 if (b) {
//                     return alloc_print(ally, "true", .{}) catch "";
//                 } else {
//                     return alloc_print(ally, "false", .{}) catch "";
//                 }
//             },
//             .none => return "null",
//         }
//     }
//
//     // pub fn Number(num: []const u8) Literal {
//     //     return Literal{ .Number = parseNumber(num) };
//     // }
//     // pub fn String(str: []const u8) Literal {
//     //     return Literal{ .String = str };
//     // }
//     // pub fn Bool(b: []const u8) Literal {
//     //     if (std.mem.eql(u8, "true", b)) {
//     //         return Literal{ .Bool = true };
//     //     } else if (std.mem.eql(u8, "false", b)) {
//     //         return Literal{ .Bool = false };
//     //     } else {
//     //         dbg_print("Invalid Bool Literal\n", .{});
//     //         std.process.exit(1);
//     //     }
//     // }
//     // pub fn None() Literal {
//     //     return Literal.none;
//     // }
// };

pub const Logical = struct {
    left: *const Expr,
    operator: Token,
    right: *const Expr,
};

pub const Set = struct {
    object: *const Expr,
    name: Token,
    value: *const Expr,
};

pub const Super = struct {
    keyword: Token,
    method: Token,
};

pub const This = struct {
    keyword: Token,
};

pub const UnaryOperator = enum(u8) {
    Minus = '-',
    Bang = '!',

    fn slice(self: @This(), alloc: std.mem.Allocator) []const u8 {
        return alloc_print(alloc, "{c}", .{@intFromEnum(self)}) catch |err| {
            dbg_print("failed to alloc_print with err: \n{any}\n", .{err});
            std.process.exit(1);
        };
    }
};
pub const Unary = struct {
    operator: UnaryOperator,
    right: *const Expr,
};

pub const Variable = struct {
    name: Token,
};

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
    assign: Assign,
    binary: Binary,
    call: Call,
    get: Get,
    grouping: Grouping,
    literal: Token.Literal,
    logical: Logical,
    set: Set,
    super: Super,
    this: This,
    unary: Unary,
    variable: Variable,

    pub fn init(expr_type: ExprType, args: anytype) !Expr {
        switch (expr_type) {
            .assign => {
                // if (args.len != 2) {
                //     dbg_print("Invalid number of arguments for assign expression.\n");
                //     dbg_print("name: Token,\nvalue: *const Expr\n");
                //     std.process.exit(1); }
                return Expr{
                    .assign = .{
                        .name = args.name,
                        .value = args.value,
                    },
                };
            },
            .binary => {},
            .call => {},
            .get => {},
            .grouping => {},
            .literal => {},
            .logical => {},
            .set => {},
            .super => {},
            .this => {},
            .unary => {},
            .variable => {},
        }
        return Expr{
            .variable = Variable{
                .name = Token.init(
                    .IDENTIFIER,
                    "asdf",
                    Token.Literal.init(.string, "asdf"),
                    1,
                ),
            },
        };
    }

    pub fn slice(self: @This(), alloc: std.mem.Allocator) []const u8 {
        switch (self) {
            .assign => |assign| {
                return alloc_print(
                    alloc,
                    "({s} {s})",
                    .{ assign.name.literal.slice(alloc), assign.value.slice(alloc) },
                ) catch |err| {
                    dbg_print("failed to alloc_print with err: \n{any}\n", .{err});
                    std.process.exit(1);
                };
            },
            .binary => |binary| {
                return alloc_print(
                    page_alloc,
                    "({s} {s} {s})",
                    .{ binary.operator.lexeme, binary.left.slice(alloc), binary.right.slice(alloc) },
                ) catch |err| {
                    dbg_print("failed to alloc_print with err: \n{any}\n", .{err});
                    std.process.exit(1);
                };
            },
            .call => return "Call",
            .get => return "Get",
            .grouping => |group| {
                return alloc_print(
                    page_alloc,
                    "({s} {s})",
                    .{ "group", group.expr.slice(alloc) },
                ) catch |err| {
                    dbg_print("failed to alloc_print with err: \n{any}\n", .{err});
                    std.process.exit(1);
                };
            },
            .literal => |literal| {
                return alloc_print(
                    page_alloc,
                    "{s}",
                    .{literal.slice(alloc)},
                ) catch |err| {
                    dbg_print("failed to alloc_print with err: \n{any}\n", .{err});
                    std.process.exit(1);
                };
            },
            .logical => return "Logical",
            .set => return "Set",
            .super => return "Super",
            .this => return "This",
            .unary => |unary| {
                return alloc_print(
                    page_alloc,
                    "({s} {s})",
                    .{ unary.operator.slice(alloc), unary.right.slice(alloc) },
                ) catch |err| {
                    dbg_print("failed to alloc_print with err: \n{any}\n", .{err});
                    std.process.exit(1);
                };
            },
            .variable => return "Variable",
        }
        return "";
    }
};

test "printing an expression" {
    const T = @import("token.zig");
    const TT = T.Type;
    const TL = T.Literal;
    const E = Expr;
    const e: E = .{
        .binary = .{
            .left = &.{
                .unary = .{
                    .operator = .Minus,
                    .right = &E{ .literal = TL.init(.number, "123") },
                },
            },
            .operator = T.init(TT.STAR, "*", TL.init(.none, null), 1),
            .right = &E{
                .grouping = .{
                    .expr = &E{
                        .literal = TL.init(.number, "123"),
                    },
                },
            },
        },
    };
    dbg_print("{s}\n", .{e.slice(page_alloc)});
}

test "init expressions" {

    // name: Token,
    // value: *const Expr,
    const a = try Expr.init(.assign, .{
        .name = Token.init(.IDENTIFIER, "foo", Token.Literal.init(.bool, "true"), 1),
        .value = &Expr{ .this = .{ .keyword = Token.init(.THIS, "this", Token.Literal.init(.string, "this"), 1) } },
    });
    dbg_print("a:{s}\n", .{a.slice(page_alloc)});
}
