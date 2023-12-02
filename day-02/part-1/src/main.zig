const std = @import("std");

const Round = struct {
    red: u64,
    green: u64,
    blue: u64,
};

const Game = std.ArrayList(Round);

const Record = std.ArrayList(Game);

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

fn parseRecord(alloc: anytype, reader: anytype) !Record {
    var rec = Record.init(alloc);
    errdefer deinitRecord(rec);

    const buffer = try alloc.alloc(u8, 1024 * 1024);
    defer alloc.free(buffer);

    while (try nextLine(reader, buffer)) |line| {
        const game = try parseGame(alloc, line);
        if (game != null) {
            try rec.append(game.?);
        }
    }

    return rec;
}

fn parseGame(alloc: anytype, line: []const u8) !?Game {
    var ln = line;
    if (ln.len < 7 or ln[0] != 'G') {
        return null;
    }

    while (ln.len > 0 and ln[0] != ':') {
        ln = ln[1..];
    }
    if (ln.len == 0) {
        return error.InvalidInput;
    }
    ln = ln[1..];

    var game = Game.init(alloc);
    errdefer game.deinit();

    while (try parseRound(&ln)) |round| {
        try game.append(round);
    }

    return game;
}

fn parseRound(line: *[]const u8) !?Round {
    var red: ?u64 = null;
    var green: ?u64 = null;
    var blue: ?u64 = null;
    inline for (0..3) |cnt| {
        if (cnt == 0) {
            consumeWs(line);
            if (line.len == 0) {
                return null;
            }
        }

        const val = parseInt(line);

        consumeWs(line);

        if (line.len == 0) {
            return error.InvalidInput;
        }

        switch (line.*[0]) {
            'r' => {
                if (red != null or line.len < 3) {
                    return error.InvalidInput;
                }
                line.* = line.*[3..];
                red = val;
            },
            'g' => {
                if (green != null or line.len < 5) {
                    return error.InvalidInput;
                }
                line.* = line.*[5..];
                green = val;
            },
            'b' => {
                if (blue != null or line.len < 4) {
                    return error.InvalidInput;
                }
                line.* = line.*[4..];
                blue = val;
            },
            else => {
                std.debug.print("{s}\n", .{line.*});
                return error.InvalidInput;
            },
        }

        while (line.len > 0 and !(line.*[0] == ',' or line.*[0] == ';')) {
            line.* = line.*[1..];
        }
        if (line.len == 0) {
            break;
        }
        if (line.*[0] == ';') {
            line.* = line.*[1..];
            break;
        }
        line.* = line.*[1..];
    }

    return .{ .red = red orelse 0, .green = green orelse 0, .blue = blue orelse 0 };
}

fn parseInt(line: *[]const u8) u64 {
    consumeWs(line);

    var val: u64 = 0;
    while (line.len > 0) {
        const ch = line.*[0];
        if (ch >= '0' and ch <= '9') {
            val = (val * 10) + @as(u64, @intCast(ch - '0'));
        } else {
            break;
        }
        line.* = line.*[1..];
    }
    return val;
}

fn consumeWs(line: *[]const u8) void {
    while (line.len > 0 and line.*[0] == ' ') {
        line.* = line.*[1..];
    }
}

fn deinitRecord(rec: Record) void {
    for (rec.items) |game| {
        game.deinit();
    }
    rec.deinit();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const stdin = std.io.getStdIn();

    var red: u64 = undefined;
    var green: u64 = undefined;
    var blue: u64 = undefined;
    var args = std.process.args();
    _ = args.next();
    inline for (0..3) |cnt| {
        if (args.next()) |arg| {
            var buf: []const u8 = arg;
            const val = parseInt(&buf);
            if (buf.len > 0) {
                std.debug.print("{s}\n", .{buf});
                return error.InvalidArgumet;
            }
            if (cnt == 0) {
                red = val;
            } else if (cnt == 1) {
                green = val;
            } else if (cnt == 2) {
                blue = val;
            }
        }
    }

    const rec = try parseRecord(alloc, stdin.reader());
    defer deinitRecord(rec);

    var sum: u64 = 0;
    outer: for (rec.items, 1..) |game, id| {
        for (game.items) |round| {
            if (round.red > red or round.green > green or round.blue > blue) {
                continue :outer;
            }
        }
        sum += id;
    }

    try std.io.getStdOut().writer().print("{}", .{sum});
}
