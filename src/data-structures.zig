const std = @import("std");

pub const EmptyMap = error{EmptyMap};

pub fn StringLruCache(comptime V: type, comptime max_size: usize) type {
    return struct {
        const Self = @This();

        const Entry = struct {
            value: V,
            order: u64, // insertion/access counter, lower = older
        };

        map: std.StringHashMap(Entry),
        counter: u64 = 0,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .map = std.StringHashMap(Entry).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn get(self: *Self, key: []const u8) ?V {
            if (self.map.getPtr(key)) |entry| {
                // update access order
                self.counter += 1;
                entry.order = self.counter;
                return entry.value;
            }
            return null;
        }

        // returns evicted value if cache is full
        pub fn put(self: *Self, key: []const u8, value: V) !?V {
            // if key already exists, just update
            if (self.map.getPtr(key)) |entry| {
                const old = entry.value;
                self.counter += 1;
                entry.value = value;
                entry.order = self.counter;
                return old;
            }

            // evict oldest entry if at capacity
            var evicted: ?V = null;
            if (self.map.count() >= max_size) {
                if (try self.evictOldest()) |_evicted| {
                    evicted = _evicted;
                }
            }

            self.counter += 1;
            try self.map.put(key, .{ .value = value, .order = self.counter });
            return evicted;
        }

        fn evictOldest(self: *Self) !?V {
            var oldest_key: ?[]const u8 = null;
            var oldest_order: u64 = std.math.maxInt(u64);

            var iter = self.map.iterator();
            while (iter.next()) |entry| {
                if (entry.value_ptr.order < oldest_order) {
                    oldest_order = entry.value_ptr.order;
                    oldest_key = entry.key_ptr.*;
                }
            }

            if (oldest_key) |k| {
                const kv = self.map.fetchRemove(k).?;
                return kv.value.value;
            }
            return null;
        }
    };
}

pub fn AutoLruCache(comptime K: type, comptime V: type, comptime max_size: usize) type {
    return struct {
        const Self = @This();

        const Entry = struct {
            value: V,
            order: u64, // insertion/access counter, lower = older
        };

        map: std.AutoHashMap(K, Entry),
        counter: u64 = 0,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .map = std.AutoHashMap(K, Entry).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn get(self: *Self, key: K) ?V {
            if (self.map.getPtr(key)) |entry| {
                // update access order
                self.counter += 1;
                entry.order = self.counter;
                return entry.value;
            }
            return null;
        }

        // returns evicted value, if cache is full
        pub fn put(self: *Self, key: K, value: V) !?V {
            // if key already exists, just update
            if (self.map.getPtr(key)) |entry| {
                const old = entry.value;
                self.counter += 1;
                entry.value = value;
                entry.order = self.counter;
                return old;
            }

            // evict oldest entry if at capacity
            var evicted: ?V = null;
            if (self.map.count() >= max_size) {
                if (try self.evictOldest()) |_evicted| {
                    evicted = _evicted;
                }
            }

            self.counter += 1;
            try self.map.put(key, .{ .value = value, .order = self.counter });
            return evicted;
        }

        fn evictOldest(self: *Self) !?V {
            var oldest_key: ?K = null;
            var oldest_order: u64 = std.math.maxInt(u64);

            var iter = self.map.iterator();
            while (iter.next()) |entry| {
                if (entry.value_ptr.order < oldest_order) {
                    oldest_order = entry.value_ptr.order;
                    oldest_key = entry.key_ptr.*;
                }
            }

            if (oldest_key) |k| {
                const kv = self.map.fetchRemove(k).?;
                return kv.value.value;
            }
            return null;
        }
    };
}
