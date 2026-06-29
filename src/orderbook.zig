const std = @import("std");
const types = @import("types.zig");

const Order = types.Order;
const Side = types.Side;
const OrderLocation = types.OrderLocation;
const Trade = types.Trade;

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

pub const OrderBook = struct {
    bids: std.AutoHashMap(u64, PriceLevel),
    asks: std.AutoHashMap(u64, PriceLevel),
    order_index: std.AutoHashMap(u64, OrderLocation),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) OrderBook {
        return .{
            .bids = std.AutoHashMap(u64, PriceLevel).init(allocator),
            .asks = std.AutoHashMap(u64, PriceLevel).init(allocator),
            .order_index = std.AutoHashMap(u64, OrderLocation).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *OrderBook) void {
        self.bids.deinit();
        self.asks.deinit();
        self.order_index.deinit();
    }

    pub fn addOrder(self: *OrderBook, order: Order) !void {
        const mapping = if (order.side == .buy) &self.bids else &self.asks;

        const result = try mapping.getOrPut(order.price);

        if (result.found_existing) {
            try result.value_ptr.addOrder(order);
        } else {
            result.value_ptr.* = PriceLevel.init(order.price, self.allocator);
            try result.value_ptr.addOrder(order);
        }

        try self.order_index.put(order.id, .{
            .side = order.side,
            .price = order.price,
        });
    }

    pub fn matchOrder(self: *OrderBook, incoming: *Order, trades: *std.ArrayList(Trade)) !void {
        const oppo_matching = if (incoming.side == .buy) &self.asks else &self.bids;

        while (incoming.quantity > 0) {
            var best_price: ?u64 = null;
            var oppo_it = oppo_matching.iterator();

            while (oppo_it.next()) |entry| {
                const price_level = entry.value_ptr.*;
                if (best_price == null) {
                    best_price = price_level.price;
                } else if (incoming.side == .buy and price_level.price < best_price.?) {
                    best_price = price_level.price;
                } else if (incoming.side == .sell and price_level.price > best_price.?) {
                    best_price = price_level.price;
                }
            }

            if (best_price == null) break;

            const hitting = if (incoming.side == .buy)
                incoming.price >= best_price.?
            else
                incoming.price <= best_price.?;

            if (!hitting) break;

            var level = oppo_matching.getPtr(best_price.?).?;
            var rest_orders = &level.orders.items[0];

            const trade_qty = @min(incoming.quantity, rest_orders.quantity);
            try trades.append(Trade{
                .buy_order_id = if (incoming.side == .buy) incoming.id else rest_orders.id,
                .sell_order_id = if (incoming.side == .sell) incoming.id else rest_orders.id,
                .price = level.price,
                .quantity = trade_qty,
                .timestamp = @intCast(std.time.nanoTimestamp()),
            });

            incoming.quantity = incoming.quantity - trade_qty;
            rest_orders.quantity = rest_orders.quantity - trade_qty;

            if (rest_orders.quantity == 0) {
                _ = level.orders.orderedRemove(0);
                if (level.orders.items.len == 0) {
                    level.deinit();
                    _ = oppo_matching.remove(best_price.?);
                }
            }
        }
        if (incoming.quantity > 0) {
            try self.addOrder(incoming.*);
        }
    }
};
