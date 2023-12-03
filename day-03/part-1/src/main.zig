const std = @import("std");

const Number = struct {
    value: u64,
    row: u64,
    col: u64,
    width: u64,
};

const SymMap = struct {
    const Self = @This();

    width: u64,
    height: u64,
    syms: std.ArrayList(bool),

    fn init(alloc: anytype) SymMap {
        return SymMap{ .width = 0, .height = 0, .syms = std.ArrayList(bool).init(alloc) };
    }

    fn deinit(self: Self) void {
        self.syms.deinit();
    }

    fn addRow(self: *Self) !void {
        try self.syms.appendNTimes(false, self.width);
        self.height += 1;
    }

    fn row(self: *Self, row_num: usize) []bool {
        const row_offset = row_num * self.width;
        return self.syms.items[row_offset..(row_offset + self.width)];
    }

    fn crow(self: *const Self, row_num: usize) []const bool {
        const row_offset = row_num * self.width;
        return self.syms.items[row_offset..(row_offset + self.width)];
    }

    fn cell(self: *Self, row_num: usize, col_num: usize) *bool {
        return &self.row(row_num)[col_num];
    }

    fn ccell(self: *const Self, row_num: usize, col_num: usize) bool {
        return self.crow(row_num)[col_num];
    }
};

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

const Schematic = struct {
    const Self = @This();

    nums: std.ArrayList(Number),
    syms: SymMap,

    fn init(alloc: anytype, reader: anytype) !Self {
        var self = Self{
            .nums = std.ArrayList(Number).init(alloc),
            .syms = SymMap.init(alloc),
        };
        errdefer self.deinit();

        var row: usize = 0;
        var buffer: [1024 * 1024]u8 = undefined;
        while (try nextLine(reader, &buffer)) |line| {
            if (self.syms.width == 0) {
                self.syms.width = line.len;
            }

            try self.syms.addRow();
            var num_width: usize = 0;
            var num: u64 = 0;
            var col: usize = 0;

            for (line) |ch| {
                if (ch != '.') {
                    self.syms.cell(row, col).* = true;
                }

                if (ch >= '0' and ch <= '9') {
                    num = (num * 10) + @as(u64, @intCast(ch - '0'));
                    num_width += 1;
                } else {
                    if (num_width > 0) {
                        try self.nums.append(Number{
                            .value = num,
                            .row = row,
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
                    .row = row,
                    .col = col - num_width,
                    .width = num_width,
                });
            }

            row += 1;
        }

        return self;
    }

    fn deinit(self: Self) void {
        self.syms.deinit();
        self.nums.deinit();
    }

    fn isPart(self: *const Self, num: *const Number) bool {
        const min = if (num.col == 0) num.col else (num.col - 1);
        const max = if (num.col + num.width >= self.syms.width) num.col + num.width else num.col + num.width + 1;
        if (num.row > 0) {
            for (min..max) |col| {
                if (self.syms.ccell(num.row - 1, col)) {
                    return true;
                }
            }
        }
        if (num.col > 0) {
            if (self.syms.ccell(num.row, num.col - 1)) {
                return true;
            }
        }
        if (num.col + num.width < self.syms.width) {
            if (self.syms.ccell(num.row, num.col + num.width)) {
                return true;
            }
        }
        if (num.row + 1 < self.syms.height) {
            for (min..max) |col| {
                if (self.syms.ccell(num.row + 1, col)) {
                    return true;
                }
            }
        }
        return false;
    }

    fn print(self: *const Self, color: bool) !void {
        var buf = std.ArrayList(u8).init(self.nums.allocator);
        defer buf.deinit();

        var num_idx: usize = 0;
        var gray = true;
        if (color) {
            try buf.appendSlice("\x1b[2m");
        }
        for (0..self.syms.height) |row| {
            var col: usize = 0;
            while (col < self.syms.width) : (col += 1) {
                if (num_idx < self.nums.items.len and self.nums.items[num_idx].row == row and self.nums.items[num_idx].col == col) {
                    if (color) {
                        if (self.isPart(&self.nums.items[num_idx])) {
                            try buf.appendSlice("\x1b[0m\x1b[32m");
                        } else {
                            try buf.appendSlice("\x1b[0m\x1b[31m");
                        }
                        gray = false;
                    }
                    col += self.nums.items[num_idx].width - 1;
                    try buf.writer().print("{d}", .{self.nums.items[num_idx].value});
                    num_idx += 1;
                } else if (self.syms.ccell(row, col)) {
                    if (color) {
                        try buf.appendSlice("\x1b[0m\x1b[1m#");
                        gray = false;
                    } else {
                        try buf.append('#');
                    }
                } else if (color and !gray) {
                    try buf.appendSlice("\x1b[0m\x1b[2m.");
                    gray = true;
                } else {
                    try buf.append('.');
                }
            }
            if (color) {
                std.debug.print("{s}\x1b[0m\n", .{buf.items});
            } else {
                std.debug.print("{s}\n", .{buf.items});
            }
            buf.clearRetainingCapacity();
            if (color) {
                try buf.appendSlice("\x1b[2m");
                gray = true;
            }
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const stdin = std.io.getStdIn();

    const schem = try Schematic.init(alloc, stdin.reader());
    defer schem.deinit();

    try schem.print(true);

    var sum: u64 = 0;
    for (schem.nums.items) |num| {
        if (schem.isPart(&num)) {
            sum += num.value;
        }
    }

    try std.io.getStdOut().writer().print("{}", .{sum});
}
