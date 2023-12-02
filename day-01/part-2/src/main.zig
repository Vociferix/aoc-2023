const std = @import("std");

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

fn tryParseDigit(buffer: []const u8) ?u64 {
    if (buffer.len == 0) {
        return null;
    }

    switch (buffer[0]) {
        '0'...'9' => {
            return @as(u64, @intCast(buffer[0] - '0'));
        },
        'o' => {
            if (buffer.len >= 3 and buffer[1] == 'n' and buffer[2] == 'e') {
                return 1;
            }
        },
        't' => {
            if (buffer.len >= 3 and buffer[1] == 'w' and buffer[2] == 'o') {
                return 2;
            }
            if (buffer.len >= 5 and buffer[1] == 'h' and buffer[2] == 'r' and buffer[3] == 'e' and buffer[4] == 'e') {
                return 3;
            }
        },
        'f' => {
            if (buffer.len >= 4 and buffer[1] == 'o' and buffer[2] == 'u' and buffer[3] == 'r') {
                return 4;
            }
            if (buffer.len >= 4 and buffer[1] == 'i' and buffer[2] == 'v' and buffer[3] == 'e') {
                return 5;
            }
        },
        's' => {
            if (buffer.len >= 3 and buffer[1] == 'i' and buffer[2] == 'x') {
                return 6;
            }
            if (buffer.len >= 5 and buffer[1] == 'e' and buffer[2] == 'v' and buffer[3] == 'e' and buffer[4] == 'n') {
                return 7;
            }
        },
        'e' => {
            if (buffer.len >= 5 and buffer[1] == 'i' and buffer[2] == 'g' and buffer[3] == 'h' and buffer[4] == 't') {
                return 8;
            }
        },
        'n' => {
            if (buffer.len >= 4 and buffer[1] == 'i' and buffer[2] == 'n' and buffer[3] == 'e') {
                return 9;
            }
        },
        'z' => {
            if (buffer.len >= 4 and buffer[1] == 'e' and buffer[2] == 'r' and buffer[3] == 'o') {
                return 0;
            }
        },
        else => {},
    }

    return null;
}

pub fn main() !void {
    const stdin = std.io.getStdIn();

    var sum: u64 = 0;
    var buffer: [1024 * 1024]u8 = undefined;
    while (try nextLine(stdin.reader(), &buffer)) |line| {
        var first: ?u64 = null;
        var last: ?u64 = null;
        for (0..line.len) |idx| {
            if (tryParseDigit(line[idx..])) |val| {
                if (first == null) {
                    first = val;
                }
                last = val;
            }
        }

        if (last == null) {
            continue;
        }

        const value: u64 = (first.? * 10) + last.?;
        sum += value;
    }

    try std.io.getStdOut().writer().print("{}", .{sum});
}
