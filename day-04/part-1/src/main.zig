const std = @import("std");

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const stdin = std.io.getStdIn();
    const reader = stdin.reader();

    var sum: u64 = 0;
    var buf: [1024 * 1024]u8 = undefined;
    var winners = std.ArrayList(u8).init(alloc);
    while (try nextLine(reader, &buf)) |line| {
        winners.clearRetainingCapacity();
        var l: []const u8 = line;
        while (l[0] != ':') {
            l = l[1..];
        }
        l = l[2..];

        while (l[0] != '|') {
            var num: u8 = l[1] - '0';
            if (l[0] != ' ') {
                num += (l[0] - '0') * 10;
            }
            try winners.append(num);
            l = l[3..];
        }
        l = l[1..];

        var val: u64 = 1;
        while (l.len != 0) {
            l = l[1..];
            var num: u8 = l[1] - '0';
            if (l[0] != ' ') {
                num += (l[0] - '0') * 10;
            }
            l = l[2..];

            for (winners.items) |winner| {
                if (num == winner) {
                    val <<= 1;
                    break;
                }
            }
        }
        val >>= 1;
        sum += val;
    }

    try std.io.getStdOut().writer().print("{}", .{sum});
}
