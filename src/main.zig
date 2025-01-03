const std = @import("std");
const Scanner = @import("Scanner.zig");
const dbg_print = std.debug.print;
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

    const file_contents = try std.fs.cwd().readFileAlloc(page_alloc, file, std.math.maxInt(usize)); defer page_alloc.free(file_contents);

    var scanner = Scanner.New(file_contents);
    _ = try scanner.scan();
    scanner.print();

}
