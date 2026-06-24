const std = @import("std");
const memory = std.mem;
const heap = std.heap;
const show = std.debug.print;
const fmtallocprint = std.fmt.allocPrint;
const http = std.http;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const url = try fmtallocprint(allocator, "http://api-point-ip-details.vercel.app/?ip={}", .{"192.168.1.1"});
    defer allocator.free(url);

    // after writing all these codes.. i came to know that this will not work with web assembly (wasm).. what a bad day.. :/
}
