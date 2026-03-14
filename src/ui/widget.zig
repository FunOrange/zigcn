const VStack = @import("../ui.zig").VStack;

pub const Widget = union(enum) {
    vstack: VStack,
};
