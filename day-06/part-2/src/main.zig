const std = @import("std");

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

const Race = struct {
    time: u64,
    dist: u64,
};

pub fn main() !void {
    const stdin = std.io.getStdIn();
    var buf: [1024 * 1024]u8 = undefined;
    var time: u64 = 0;
    var dist: u64 = 0;

    var line = (try nextLine(stdin.reader(), &buf)) orelse return error.InvalidInput;
    for (line) |ch| {
        if (ch >= '0' and ch <= '9') {
            time = (time * 10) + (ch - '0');
        }
    }
    line = (try nextLine(stdin.reader(), &buf)) orelse return error.InvalidInput;
    for (line) |ch| {
        if (ch >= '0' and ch <= '9') {
            dist = (dist * 10) + (ch - '0');
        }
    }

    const t_sq = time * time;
    const d4 = dist * 4;
    const delt = std.math.sqrt(t_sq - d4);
    var lower = (time - delt) / 2;
    var upper = (time + delt) / 2;

    while (lower * (time - lower) <= dist) {
        lower += 1;
    }
    while (upper * (time - upper) <= dist) {
        upper -= 1;
    }

    try std.io.getStdOut().writer().print("{}", .{upper - lower + 1});
}
