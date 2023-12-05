const std = @import("std");

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return std.mem.trimRight(u8, line, "\r");
}

const Range = struct {
    begin: u64,
    end: u64,
};

const Mapping = struct {
    src: Range,
    dst: Range,
};

const Map = std.ArrayList(Mapping);

fn consumeWs(line: *[]const u8) void {
    while (line.len > 0 and line.*[0] == ' ') {
        line.* = line.*[1..];
    }
}

fn readNum(line: *[]const u8) ?u64 {
    consumeWs(line);
    if (line.len == 0) {
        return null;
    }

    var val: u64 = 0;

    while (line.len > 0 and line.*[0] >= '0' and line.*[0] <= '9') {
        val = (val * 10) + @as(u64, @intCast(line.*[0] - '0'));
        line.* = line.*[1..];
    }

    return val;
}

fn readMap(reader: anytype, buf: []u8, map: *Map) !void {
    _ = (try nextLine(reader, buf)) orelse return error.InvalidInput;

    while (true) {
        var line = (try nextLine(reader, buf)) orelse break;
        consumeWs(&line);
        if (line.len == 0) {
            break;
        }

        const dst = readNum(&line) orelse return error.InvalidInput;
        const src = readNum(&line) orelse return error.InvalidInput;
        const len = readNum(&line) orelse return error.InvalidInput;

        const entry = Mapping{
            .src = Range{
                .begin = src,
                .end = src + len,
            },
            .dst = Range{
                .begin = dst,
                .end = dst + len,
            },
        };

        try map.append(entry);
    }
}

fn resolve(src: u64, map: *const Map) u64 {
    for (map.items) |entry| {
        if (src >= entry.src.begin and src < entry.src.end) {
            return entry.dst.begin + (src - entry.src.begin);
        }
    }
    return src;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const stdin = std.io.getStdIn();
    const reader = stdin.reader();

    var seeds = std.ArrayList(u64).init(alloc);
    var seed_to_soil = Map.init(alloc);
    var soil_to_fert = Map.init(alloc);
    var fert_to_water = Map.init(alloc);
    var water_to_light = Map.init(alloc);
    var light_to_temp = Map.init(alloc);
    var temp_to_hum = Map.init(alloc);
    var hum_to_loc = Map.init(alloc);

    var buf: [1024 * 1024]u8 = undefined;

    var line = (try nextLine(reader, &buf)) orelse return error.InvalidInput;
    line = line[6..];
    while (readNum(&line)) |seed| {
        try seeds.append(seed);
    }

    _ = (try nextLine(reader, &buf)) orelse return error.InvalidInput;

    try readMap(reader, &buf, &seed_to_soil);
    try readMap(reader, &buf, &soil_to_fert);
    try readMap(reader, &buf, &fert_to_water);
    try readMap(reader, &buf, &water_to_light);
    try readMap(reader, &buf, &light_to_temp);
    try readMap(reader, &buf, &temp_to_hum);
    try readMap(reader, &buf, &hum_to_loc);

    for (seeds.items) |*val| {
        val.* = resolve(val.*, &seed_to_soil);
        val.* = resolve(val.*, &soil_to_fert);
        val.* = resolve(val.*, &fert_to_water);
        val.* = resolve(val.*, &water_to_light);
        val.* = resolve(val.*, &light_to_temp);
        val.* = resolve(val.*, &temp_to_hum);
        val.* = resolve(val.*, &hum_to_loc);
    }

    const closest = seeds.items[std.mem.indexOfMin(u64, seeds.items)];

    try std.io.getStdOut().writer().print("{}", .{closest});
}
