const VStack = @import("./vstack.zig").VStack;

pub const Widget = union(enum) {
    vstack: VStack,
};
