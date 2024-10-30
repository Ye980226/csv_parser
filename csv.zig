const std = @import("std");

const Person = struct { name: []const u8, age: u32, height: f32, weight: f64, is_sell: bool };

// 递归解析 CSV 行
fn parse_csv_line(comptime line: []const u8, comptime T: type) T {
    comptime var field_index: usize = 0;
    comptime var start: usize = 0;
    comptime var result: T = undefined;

    inline for (line, 0..) |c, i| {
        if (c == ',' or i == line.len - 1) {
            const end = if (i == line.len - 1 and c != ',') i + 1 else i;
            const slice = comptime line[start..end];
            parse_field(T, &result, field_index, slice);
            field_index += 1;
            start = i + 1;
        }
    }

    return comptime result;
}

// 解析字段，根据字段类型处理
fn parse_field(comptime T: type, comptime result: *T, comptime field_index: usize, comptime slice: []const u8) void {
    const field_info = @typeInfo(T).Struct.fields[field_index];
    const field_type = field_info.type;
    const field_name = field_info.name;

    switch (field_type) {
        []const u8 => {
            @field(result.*, field_name) = slice;
        },

        u32, u64, i32, i64 => {
            @field(result.*, field_name) = parseInteger(field_type, slice);
        },
        bool => {
            @field(result.*, field_name) = parseBool(slice);
        },
        f32, f64 => {
            @field(result.*, field_name) = parseFloat(field_type, slice);
        },
        else => @compileError("Unsupported field type"),
    }
}

fn parseBool(comptime s: []const u8) bool {

    // 处理 'true' 和 'false' 字符串
    if (std.mem.eql(u8, s, "true")) {
        return true;
    } else if (std.mem.eql(u8, s, "false")) {
        return false;
    }

    // 处理 '1' 和 '0' 字符表示
    if (s.len == 1) {
        if (s[0] == '1') {
            return true;
        } else if (s[0] == '0') {
            return false;
        }
    }
    // 如果解析失败，抛出编译期错误
    @compileError("Invalid boolean representation");
}

// 解析整数
fn parseInteger(comptime T: type, comptime s: []const u8) T {
    var result: u32 = 0;
    inline for (s) |c| {
        if (c >= '0' and c <= '9') {
            result = result * 10 + @as(T, c - '0');
        }
    }
    return comptime result;
}

// 解析浮点数
fn parseFloat(comptime T: type, comptime s: []const u8) T {
    return comptime std.fmt.parseFloat(T, s) catch 0.0;
}

// 加载 CSV 数据
fn load_csv_data(comptime T: type, comptime data_path: []const u8, comptime N: usize) [N]T {
    const raw_data: []const u8 = @embedFile(data_path);
    comptime var data_array: [N]T = undefined;
    comptime var index: usize = 0;
    comptime var line_start: usize = 0;

    inline while (index < N and line_start < raw_data.len) {
        const line_end: usize = comptime std.mem.indexOf(u8, raw_data[line_start..], "\n") orelse raw_data.len - line_start + 1;

        // const line_end: usize = line_start + 1;
        const line: []const u8 = comptime raw_data[line_start .. line_start + line_end - 1];
        if (line.len > 0) {
            data_array[index] = comptime parse_csv_line(line, T);
            index += 1;
        }
        line_start += line_end + 1;
    }
    return comptime data_array;
}

fn get_csv_data_len(comptime data_path: []const u8) usize {
    comptime var N: usize = 0;

    // comptime var data_array: [N]T = undefined;
    const raw_data: []const u8 = @embedFile(data_path);
    comptime var line_iter = std.mem.splitAny(u8, raw_data, "\n");
    inline while (comptime line_iter.next()) |_| {
        N += 1;
    }
    return comptime N;
}

pub fn main() void {
    const data_path: []const u8 = "data.csv";
    const N = comptime get_csv_data_len(data_path);
    // comptime var people: [3]Person = undefined;
    const people = comptime load_csv_data(Person, data_path, N);

    std.debug.print("N:{d}\n", .{N});
    for (people) |person| {
        std.debug.print("Name: {s}, Age: {d}, Height: {any}, Weight: {any}, IsSell: {any}\n", .{ person.name, person.age, person.height, person.weight, person.is_sell });
    }
}
