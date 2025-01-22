const std = @import("std");
const dbg_print = std.debug.print;
const page_alloc = std.heap.page_allocator;

const Token = @import("Token.zig");
const Scanner = @import("Scanner.zig");
const Parser = @import("Parser.zig");

const valid_commands = [_][]const u8{ "tokenize", "parse" };
var command = std.ArrayList(u8).init(page_alloc);
var filename = std.ArrayList(u8).init(page_alloc);

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

    if (!isValidCommand(command.items)) {
        dbg_print("Unknown command: {s}\n", .{command.items});
        std.process.exit(1);
    }
}

pub fn main() !void {
    try init();
    const file = try filename.toOwnedSlice();
    defer page_alloc.free(file);

    const file_contents = try std.fs.cwd().readFileAlloc(page_alloc, file, std.math.maxInt(usize));
    defer page_alloc.free(file_contents);

    var scanner = Scanner.init(file_contents, page_alloc);
    defer scanner.deinit();
    try scanner.tokenize();

    var parser = Parser.init(scanner.token_list, page_alloc);

    if (std.mem.eql(u8, command.items, "tokenize")) {
        scanner.print();
    } else if (std.mem.eql(u8, command.items, "parse")) {
        parser.print();
    }
}
