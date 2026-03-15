const std = @import("std");

pub const EmptyMap = error{EmptyMap};

pub fn StringLruCache(comptime V: type, comptime max_size: usize) type {
    return LruCache([]const u8, V, std.hash_map.StringContext, max_size);
}

pub fn AutoLruCache(comptime K: type, comptime V: type, comptime max_size: usize) type {
    return LruCache(K, V, std.hash_map.AutoContext(K), max_size);
}

pub fn LruCache(comptime K: type, comptime V: type, comptime Context: type, comptime max_size: usize) type {
    std.debug.assert(max_size > 0);

    return struct {
        const Self = @This();

        const Index = std.math.IntFittingRange(0, max_size);
        const null_index = std.math.maxInt(Index);

        pub const Entry = struct {
            value: V,
            node_idx: Index,
        };

        const Node = struct {
            key: K,
            prev: Index = null_index,
            next: Index = null_index,
        };

        map: std.HashMap(K, Entry, Context, std.hash_map.default_max_load_percentage),
        nodes: []Node,
        allocator: std.mem.Allocator,

        head: Index = null_index, // Most recently used
        tail: Index = null_index, // Least recently used
        free_head: Index = 0, // Head of the free list

        pub fn init(allocator: std.mem.Allocator) Self {
            const nodes = allocator.alloc(Node, max_size) catch unreachable;
            for (nodes, 0..) |*node, i| {
                node.next = if (i + 1 < max_size) @intCast(i + 1) else null_index;
                node.prev = null_index;
            }

            var map = std.HashMap(K, Entry, Context, std.hash_map.default_max_load_percentage).init(allocator);
            map.ensureTotalCapacity(max_size) catch unreachable;

            return .{
                .map = map,
                .nodes = nodes,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
            self.allocator.free(self.nodes);
            self.* = undefined;
        }

        pub fn get(self: *Self, key: K) ?V {
            if (self.map.getPtr(key)) |entry| {
                self.moveToHead(entry.node_idx);
                return entry.value;
            }
            return null;
        }

        // Returns evicted value if cache is full
        pub fn put(self: *Self, key: K, value: V) !?V {
            if (self.map.getPtr(key)) |entry| {
                const old_value = entry.value;
                entry.value = value;
                self.moveToHead(entry.node_idx);
                return old_value;
            }

            var evicted_value: ?V = null;
            var idx: Index = undefined;

            if (self.free_head != null_index) {
                // Consume from free list
                idx = self.free_head;
                self.free_head = self.nodes[idx].next;
            } else {
                // Evict tail (least recently used)
                idx = self.tail;
                std.debug.assert(idx != null_index);

                const tail_node = &self.nodes[idx];

                if (self.map.fetchRemove(tail_node.key)) |kv| {
                    evicted_value = kv.value.value;
                }

                self.removeNode(idx);
            }

            self.nodes[idx] = .{
                .key = key,
            };

            // Map has guaranteed capacity, so this will never allocate
            self.map.putAssumeCapacity(key, .{ .value = value, .node_idx = idx });
            self.insertAtHead(idx);

            return evicted_value;
        }

        fn moveToHead(self: *Self, idx: Index) void {
            if (self.head == idx) return;
            self.removeNode(idx);
            self.insertAtHead(idx);
        }

        fn removeNode(self: *Self, idx: Index) void {
            const node = &self.nodes[idx];

            if (node.prev != null_index) {
                self.nodes[node.prev].next = node.next;
            } else {
                self.head = node.next;
            }

            if (node.next != null_index) {
                self.nodes[node.next].prev = node.prev;
            } else {
                self.tail = node.prev;
            }
        }

        fn insertAtHead(self: *Self, idx: Index) void {
            const node = &self.nodes[idx];
            node.next = self.head;
            node.prev = null_index;

            if (self.head != null_index) {
                self.nodes[self.head].prev = idx;
            }
            self.head = idx;

            if (self.tail == null_index) {
                self.tail = idx;
            }
        }
    };
}
