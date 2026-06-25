const std = @import("std");
const show = std.debug.print;
const Side = enum {
    buy,
    sell,
};

const OrderStatus = enum {
    new,
    partially_filled,
    filled,
    cancelled,
};

const Order = struct {
    id: u64,
    side: Side,
    quantity: u64,
    price: u64,
    timestamp: u128,
    status: OrderStatus,
};

const PriceLevel = struct {
    price: u64,
    orders: std.ArrayList(Order),

    fn init(price: u64, allocator: std.mem.Allocator) PriceLevel {
        return .{
            .price = price,
            .orders = std.ArrayList(Order).init(allocator),
        };
    }

    fn addOrder(self: *PriceLevel, order: Order) !void {
        try self.orders.append(order);
    }

    fn totalQuantity(self: *const PriceLevel) u64 {
        var total: u64 = 0;
        for (self.orders.items) |order| {
            total = total + order.quantity;
        }
        return total;
    }

    fn deinit(self: *PriceLevel) void {
        self.orders.deinit();
    }
};

fn createOrder(id: u64, side: Side, quantity: u64, price: u64) Order {
    std.debug.assert(price > 0.0);
    std.debug.assert(quantity > 0);

    return Order{
        .id = id,
        .side = side,
        .quantity = quantity,
        .price = price,
        .timestamp = @intCast(std.time.nanoTimestamp()),
        .status = .new,
    };
}

fn statusToString(status: OrderStatus) []const u8 {
    return switch (status) {
        .new => "NEW",
        .partially_filled => "PARTIAL",
        .filled => "FILLED",
        .cancelled => "CANCELLED",
    };
}

fn sideToString(side: Side) []const u8 {
    return switch (side) {
        .buy => "BUY",
        .sell => "SELL",
    };
}

fn toTicks(price: f64) u64 {
    return @intFromFloat(price * 100.0);
}

pub fn main() !void {
    const writer = std.io.getStdOut().writer();
    const alloc = std.heap.page_allocator;

    var level = PriceLevel.init(150.50, alloc);
    defer level.deinit();

    try level.addOrder(createOrder(1, .buy, 100, 150.50));
    try level.addOrder(createOrder(4, .buy, 150, 150.50));
    try level.addOrder(createOrder(7, .buy, 50, 150.50));

    try writer.print("=== Price Level @ {d:.2} ===\n", .{level.price});
    try writer.print("Total Orders: {d}\n", .{level.orders.items.len});
    try writer.print("Total Quantity: {d}\n", .{level.totalQuantity()});

    try writer.print("\nIndividual Orders:\n", .{});
    for (level.orders.items) |order| {
        try writer.print(
            "  ID={d} | {s} | Qty={d}\n",
            .{ order.id, sideToString(order.side), order.quantity },
        );
    }
}
