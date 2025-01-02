const std = @import("std");
const print = std.debug.print;

pub const Scanner = struct {
    icurr: usize,
    line: usize,
    skipChar: bool,
    skipNext: usize,
    source: []const u8,
    tokenList: TokenList,
    unexpectedCharError: bool,
};
