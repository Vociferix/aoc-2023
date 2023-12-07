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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const stdin = std.io.getStdIn();
    var buf: [1024 * 1024]u8 = undefined;

    var races = std.ArrayList(Race).init(alloc);

    var line = (try nextLine(stdin.reader(), &buf)) orelse return error.InvalidInput;
    while (line.len != 0 and line[0] != ':') {
        line = line[1..];
    }
    if (line.len == 0) {
        return error.InvalidInput;
    }
    line = line[1..];
    while (true) {
        while (line.len != 0 and line[0] == ' ') {
            line = line[1..];
        }
        if (line.len == 0) {
            break;
        }
        var val: u64 = 0;
        while (line.len != 0 and line[0] >= '0' and line[0] <= '9') {
            val = (val * 10) + @as(u64, @intCast(line[0] - '0'));
            line = line[1..];
        }
        if (line.len != 0 and line[0] != ' ') {
            return error.InvalidInput;
        }
        try races.append(Race{ .time = val, .dist = undefined });
    }

    line = (try nextLine(stdin.reader(), &buf)) orelse return error.InvalidInput;
    while (line.len != 0 and line[0] != ':') {
        line = line[1..];
    }
    if (line.len == 0) {
        return error.InvalidInput;
    }
    line = line[1..];
    for (races.items) |*race| {
        while (line.len != 0 and line[0] == ' ') {
            line = line[1..];
        }
        if (line.len == 0) {
            return error.InvalidInput;
        }
        var val: u64 = 0;
        while (line.len != 0 and line[0] >= '0' and line[0] <= '9') {
            val = (val * 10) + @as(u64, @intCast(line[0] - '0'));
            line = line[1..];
        }
        if (line.len != 0 and line[0] != ' ') {
            return error.InvalidInput;
        }
        race.dist = val;
    }
    while (line.len != 0 and line[0] == ' ') {
        line = line[1..];
    }
    if (line.len != 0) {
        return error.InvalidInput;
    }

    var prod: u64 = 1;
    for (races.items) |*race| {
        const t_sq = race.time * race.time;
        const d4 = race.dist * 4;
        if (t_sq < d4) {
            prod = 0;
            break;
        }
        const delt = std.math.sqrt(t_sq - d4);
        var lower = (race.time - delt) / 2;
        var upper = (race.time + delt) / 2;

        while (lower * (race.time - lower) <= race.dist) {
            lower += 1;
        }
        while (upper * (race.time - upper) <= race.dist) {
            upper -= 1;
        }

        prod *= (upper - lower) + 1;
    }

    try std.io.getStdOut().writer().print("{}", .{prod});
}
