const std = @import("std");
const show = std.debug.print;

const Side = enum {
    buy,
    sell,
};

const Order = struct {
    id: u64,
    side: Side,
    quantity: u64,
    price: f64,
    timestamp: u128,
};

fn createOrder(id: u64, side: Side, quantity: u64, price: f64) Order {
    std.debug.assert(price > 0.0);
    std.debug.assert(quantity > 0);

    const timestamp: u128 = @intCast(std.time.nanoTimestamp()); //typecasting spell lol;

    return Order{ .id = id, .side = side, .quantity = quantity, .price = price, .timestamp = timestamp };
}

pub fn main() !void {
    const order1 = createOrder(1, .buy, 100, 150.50);
    const order2 = createOrder(2, .sell, 50, 152.00);

    // Print with match for side
    show("Order 1: ID={d}, Side={s}, Qty={d}, Price={d}\n", .{
        order1.id,
        if (order1.side == .buy) "BUY" else "SELL",
        order1.quantity,
        order1.price,
    });

    show("Order 2: ID={d}, Side={s}, Qty={d}, Price={d}\n", .{
        order2.id,
        if (order2.side == .buy) "BUY" else "SELL",
        order2.quantity,
        order2.price,
    });
}
