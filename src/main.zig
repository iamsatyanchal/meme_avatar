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

    show("\n[1] Initial State: One SELL order of 30 shares @ 151.50\n", .{});

    try book.addOrder(types.createOrder(11, .sell, 30, types.toTicks(151.50)));

    show("\n[2] Incoming BUY: 100 shares @ 152.00\n", .{});
    var new_buy = types.createOrder(20, .buy, 100, types.toTicks(152.00));
    try book.matchOrder(&new_buy, &trades);

    show("\n[3] Trades Executed:\n", .{});
    for (trades.items) |trade| {
        show("  BUY#{d} <-> SELL#{d} | Qty: {d} | Price:{d:.2}\n", .{
            trade.buy_order_id,
            trade.sell_order_id,
            trade.quantity,
            types.toFloat(trade.price),
        });
    }

    show("\n[4] Incoming Order Remaining (70 hona chahiye): {d}\n", .{new_buy.quantity});
}
