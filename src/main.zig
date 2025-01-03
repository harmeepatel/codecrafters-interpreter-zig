const std = @import("std");
// const Scanner = @import("Scanner.zig");
const dbg_print = std.debug.print;
const page_alloc = std.heap.page_allocator;

var cmmand = std.ArrayList(u8).init(page_alloc);
var flename = std.ArrayList(u8).init(page_alloc);

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
try cmmand.appendSlice(args[1]);
    try flename.appendSlice(args[2]);

    const cmd_slc = try cmmand.toOwnedSlice();
    defer page_alloc.free(cmd_slc);
    if (!isValidCommand(cmd_slc)) {
        dbg_print("Unknown command: {s}\n", .{cmd_slc});
        std.process.exit(1);
    }
}

pub fn main() !void {
    // _ = try init();
    // const file = try filename.toOwnedSlice();
    // defer page_alloc.free(file);
    //
    // const file_contents = try std.fs.cwd().readFileAlloc(page_alloc, file, std.math.maxInt(usize));
    // defer page_alloc.free(file_contents);

    // var scanner = Scanner.New(file_contents);
    // _ = try scanner.scan();
    // scanner.print();

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    std.debug.print("Logs from your program will appear here!\n", .{});

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }

    const command = args[1];
    const filename = args[2];

    if (!std.mem.eql(u8, command, "tokenize")) {
        std.debug.print("Unknown command: {s}\n", .{command});
        std.process.exit(1);
    }

    const file_contents = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, filename, std.math.maxInt(usize));
    defer std.heap.page_allocator.free(file_contents);

    // Uncomment this block to pass the first stage
    // if (file_contents.len > 0) {
    //     @panic("Scanner not implemented");
    // } else {
    //     try std.io.getStdOut().writer().print("EOF  null\n", .{}); // Placeholder, remove this line when implementing the scanner
    // }

}
