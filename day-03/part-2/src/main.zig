const std = @import("std");

const Number = struct {
    value: u64,
    row: u64,
    col: u64,
    width: usize,
};

const Symbol = struct {
    symb: u8,
    row: u64,
    col: u64,
    num: ?*Number,
};

fn numberPtrLessThan(ctx: void, lhs: ?*const Number, rhs: ?*const Number) bool {
    _ = ctx;
    if (lhs) |l| {
        if (rhs) |r| {
            return @as(usize, @intFromPtr(l)) < @as(usize, @intFromPtr(r));
        } else {
            return true;
        }
    } else {
        return false;
    }
}

const Schematic = struct {
    const Self = @This();

    width: usize,
    height: usize,
    nums: std.ArrayList(Number),
    symbs: std.ArrayList(Symbol),
    entries: std.ArrayList(?*Symbol),

    fn init(alloc: anytype, reader: anytype) !Self {
        var self = Self{
            .width = 0,
            .height = 0,
            .nums = std.ArrayList(Number).init(alloc),
            .symbs = std.ArrayList(Symbol).init(alloc),
            .entries = std.ArrayList(?*Symbol).init(alloc),
        };
        errdefer self.deinit();

        var r: usize = 0;
        var buffer: [1024 * 1024]u8 = undefined;
        while (try nextLine(reader, &buffer)) |line| {
            if (self.width < line.len) {
                self.width = line.len;
            }

            var num_width: usize = 0;
            var num: u64 = 0;
            var col: usize = 0;

            for (line) |ch| {
                if (ch != '.') {
                    try self.symbs.append(Symbol{
                        .symb = ch,
                        .row = r,
                        .col = col,
                        .num = null,
                    });
                }

                if (ch >= '0' and ch <= '9') {
                    num = (num * 10) + @as(u64, @intCast(ch - '0'));
                    num_width += 1;
                } else {
                    if (num_width > 0) {
                        try self.nums.append(Number{
                            .value = num,
                            .row = r,
                            .col = col - num_width,
                            .width = num_width,
                        });
                        num = 0;
                        num_width = 0;
                    }
                }

                col += 1;
            }

            if (num_width > 0) {
                try self.nums.append(Number{
                    .value = num,
                    .row = r,
                    .col = col - num_width,
                    .width = num_width,
                });
            }

            r += 1;
            self.height += 1;
        }

        try self.entries.appendNTimes(null, r * self.width);

        for (self.symbs.items) |*symb| {
            const pos = (symb.row * self.width) + symb.col;
            self.entries.items[pos] = symb;
        }

        for (self.nums.items) |*num| {
            const pos = (num.row * self.width) + num.col;
            for (pos..(pos + num.width)) |p| {
                self.entries.items[p].?.num = num;
            }
        }

        return self;
    }

    fn deinit(self: Self) void {
        self.entries.deinit();
        self.symbs.deinit();
        self.nums.deinit();
    }

    fn cell(self: *const Self, row_num: usize, col_num: usize) ?*const Symbol {
        if (row_num >= self.height or col_num >= self.width) {
            return null;
        }

        const pos = (row_num * self.width) + col_num;
        return self.entries.items[pos];
    }

    fn getNeighborsOf(self: *const Self, symb: *const Symbol, buf: *[8]*const Symbol) []*const Symbol {
        var count: usize = 0;
        if (symb.row > 0) {
            if (symb.col > 0) {
                if (self.cell(symb.row - 1, symb.col - 1)) |s| {
                    buf[count] = s;
                    count += 1;
                }
            }
            if (self.cell(symb.row - 1, symb.col)) |s| {
                if (s.num) |num| {
                    if (count == 0 or buf[count - 1].num != num) {
                        buf[count] = s;
                        count += 1;
                    }
                } else {
                    buf[count] = s;
                    count += 1;
                }
            }
            if (symb.col + 1 < self.width) {
                if (self.cell(symb.row - 1, symb.col + 1)) |s| {
                    if (s.num) |num| {
                        if (count == 0 or buf[count - 1].num != num) {
                            buf[count] = s;
                            count += 1;
                        }
                    } else {
                        buf[count] = s;
                        count += 1;
                    }
                }
            }
        }
        if (symb.col > 0) {
            if (self.cell(symb.row, symb.col - 1)) |s| {
                if (s.num) |num| {
                    if (count == 0 or buf[count - 1].num != num) {
                        buf[count] = s;
                        count += 1;
                    }
                } else {
                    buf[count] = s;
                    count += 1;
                }
            }
        }
        if (symb.col + 1 < self.width) {
            if (self.cell(symb.row, symb.col + 1)) |s| {
                if (s.num) |num| {
                    if (count == 0 or buf[count - 1].num != num) {
                        buf[count] = s;
                        count += 1;
                    }
                } else {
                    buf[count] = s;
                    count += 1;
                }
            }
        }
        if (symb.row + 1 < self.height) {
            if (symb.col > 0) {
                if (self.cell(symb.row + 1, symb.col - 1)) |s| {
                    if (s.num) |num| {
                        if (count == 0 or buf[count - 1].num != num) {
                            buf[count] = s;
                            count += 1;
                        }
                    } else {
                        buf[count] = s;
                        count += 1;
                    }
                }
            }
            if (self.cell(symb.row + 1, symb.col)) |s| {
                if (s.num) |num| {
                    if (count == 0 or buf[count - 1].num != num) {
                        buf[count] = s;
                        count += 1;
                    }
                } else {
                    buf[count] = s;
                    count += 1;
                }
            }
            if (symb.col + 1 < self.width) {
                if (self.cell(symb.row + 1, symb.col + 1)) |s| {
                    if (s.num) |num| {
                        if (count == 0 or buf[count - 1].num != num) {
                            buf[count] = s;
                            count += 1;
                        }
                    } else {
                        buf[count] = s;
                        count += 1;
                    }
                }
            }
        }

        return buf[0..count];
    }

    fn gearRatio(self: *const Self, symb: ?*const Symbol) ?u64 {
        if (symb) |sy| {
            if (sy.symb != '*') {
                return null;
            }

            var buf: [8]*const Symbol = undefined;
            const neighbors = self.getNeighborsOf(sy, &buf);
            if (neighbors.len != 2 or neighbors[0].num == null or neighbors[1].num == null) {
                return null;
            }

            return neighbors[0].num.?.value * neighbors[1].num.?.value;
        } else {
            return null;
        }
    }

    fn isPart(self: *const Self, num: ?*const Number) bool {
        if (num) |n| {
            const min = if (n.col > 0) (n.col - 1) else n.col;
            const max = if (n.col + 1 < self.width) (n.col + n.width + 1) else (n.col + n.width);
            if (n.row > 0) {
                for (min..max) |c| {
                    if (self.cell(n.row - 1, c) != null) {
                        return true;
                    }
                }
            }
            if (n.col > 0 and self.cell(n.row, n.col - 1) != null) {
                return true;
            }
            if (n.col + n.width < self.width and self.cell(n.row, n.col + n.width) != null) {
                return true;
            }
            if (n.row + 1 < self.height) {
                for (min..max) |c| {
                    if (self.cell(n.row + 1, c) != null) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    fn print(self: *const Self, comptime color: bool) !void {
        var buf = std.ArrayList(u8).init(self.nums.allocator);
        defer buf.deinit();

        if (!color) {
            try buf.reserve(self.width);
        }

        var gray = false;
        var num_color = false;
        for (0..self.height) |row| {
            for (0..self.width) |col| {
                if (self.cell(row, col)) |symb| {
                    if (color) {
                        if (symb.num) |num| {
                            if (num_color) {
                                try buf.append(symb.symb);
                            } else {
                                if (self.isPart(num)) {
                                    try buf.writer().print("\x1b[0m\x1b[32m{c}", .{symb.symb});
                                } else {
                                    try buf.writer().print("\x1b[0m\x1b[31m{c}", .{symb.symb});
                                }
                                num_color = true;
                            }
                        } else if (symb.symb == '*' and self.gearRatio(symb) != null) {
                            try buf.writer().print("\x1b[0m\x1b[1m\x1b[33m{c}", .{symb.symb});
                            num_color = false;
                        } else {
                            try buf.writer().print("\x1b[0m\x1b[1m{c}", .{symb.symb});
                            num_color = false;
                        }
                        gray = false;
                    } else {
                        try buf.append(symb.symb);
                    }
                } else {
                    if (color and !gray) {
                        try buf.appendSlice("\x1b[0m\x1b[2m.");
                        gray = true;
                        num_color = false;
                    } else {
                        try buf.append('.');
                    }
                }
            }
            if (color) {
                std.debug.print("{s}\x1b[0m\n", .{buf.items});
                gray = false;
                num_color = false;
            } else {
                std.debug.print("{s}\n", .{buf.items});
            }
            buf.clearRetainingCapacity();
        }
    }
};

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const stdin = std.io.getStdIn();

    const schem = try Schematic.init(alloc, stdin.reader());
    defer schem.deinit();

    try schem.print(true);

    var part2: u64 = 0;
    for (schem.symbs.items) |*symb| {
        if (schem.gearRatio(symb)) |ratio| {
            part2 += ratio;
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{part2});
}
