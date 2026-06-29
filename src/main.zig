const std = @import("std");
const types = @import("types.zig");
const orderbook = @import("orderbook.zig");

const show = std.debug.print;

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    var book = orderbook.OrderBook.init(alloc);
    defer book.deinit();

    var trades = std.ArrayList(types.Trade).init(alloc);
    defer trades.deinit();

    show("\n[PHASE 1: MATCHING]\n", .{});
    try book.addOrder(types.createOrder(11, .sell, 30, types.toTicks(151.50)));
    var new_buy = types.createOrder(20, .buy, 100, types.toTicks(152.00));
    try book.matchOrder(&new_buy, &trades);

    show("Trade Qty: {d}\n", .{trades.items[0].quantity});
    show("Remaining Incoming Qty: {d}\n", .{new_buy.quantity});

    show("\n[PHASE 2: CANCEL]\n", .{});
    try book.addOrder(types.createOrder(50, .buy, 500, types.toTicks(150.00)));
    show("Added Order 50. Cancelling now...\n", .{});

    const cancelled = try book.cancelOrder(50);
    if (cancelled) {
        show("Order 50 Successfully Cancelled!\n", .{});
    }

    show("\n[PHASE 3: MODIFY]\n", .{});
    try book.addOrder(types.createOrder(99, .sell, 100, types.toTicks(155.00)));

    show("Modifying Order 99 (Qty 100 -> 50)...\n", .{});
    _ = try book.modifyOrder(99, 100, .sell, 50, types.toTicks(155.00), &trades);

    show("Order Book Updated. (Internally 99 cancelled, 100 added)\n", .{});

    show("\n[PHASE 4: EDGE CASE]\n", .{});
    const fake_cancel = try book.cancelOrder(9999); // Ye order exist nahi karta
    if (!fake_cancel) {
        show("Correctly handled: Order 9999 not found.\n", .{});
    }
}
