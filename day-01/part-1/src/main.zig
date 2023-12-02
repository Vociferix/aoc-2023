const std = @import("std");

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

pub fn main() !void {
    const stdin = std.io.getStdIn();

    var sum: u64 = 0;
    var buffer: [1024 * 1024]u8 = undefined;
    while (try nextLine(stdin.reader(), &buffer)) |line| {
        var first: ?u8 = null;
        var last: ?u8 = null;
        for (line) |ch| {
            if (ch >= '0' and ch <= '9') {
                if (first == null) {
                    first = ch;
                }
                last = ch;
            }
        }

        if (last == null) {
            continue;
        }

        const val: u64 = @as(u64, @intCast(first.? - '0')) * 10 + @as(u64, @intCast(last.? - '0'));
        sum += val;
    }

    try std.io.getStdOut().writer().print("{}", .{sum});
}
