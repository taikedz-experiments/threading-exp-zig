// With some help from
// https://noelmrtn.fr/posts/zig_threading/

const std = @import("std");
const Thread = std.Thread;

var LINE:u8 = 0;

fn sleepy(name:[]const u8, steps:u8, mut:*Thread.Mutex, wg:*Thread.WaitGroup) void {
    var i:u8 = 0;
    wg.start();
    defer wg.finish();

    while (i < steps) {
        std.time.sleep(1 * std.time.ns_per_s);

        {
            mut.lock();
            defer mut.unlock();

            LINE += 1;
            i += 1;
            std.debug.print("{d} {s}\n", .{LINE, name});
        }
    }
}

pub fn main() !void {

    // ----- Memory
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // ----- Thread safety wrapping
    var tsafe_allocator: std.heap.ThreadSafeAllocator = .{
        .child_allocator = gpa.allocator(),
    };
    const alloc = tsafe_allocator.allocator();

    // To wait on threads we need a waitgroup, and a thread pool
    //   to wrap the waitgroup.
    // Bonus observation: declaring the struct sets it up with its defaults
    //   so delcaring "undefined" here actually works....????!!!!
    var wg:Thread.WaitGroup = undefined;
    wg.reset(); // mandatory on start

    var pool:Thread.Pool = undefined;
    try pool.init(.{.allocator = alloc});
    defer pool.deinit();

    // A mutex to ensure we don't write the counter simultaneously
    var mut:Thread.Mutex = undefined;

    // Use OS Thread spawning, pass in a function, and the arguments to pass
    //   down to it in an anonymous struct
    _ = try std.Thread.spawn(.{}, sleepy, .{"One", 1, &mut, &wg});
    _ = try std.Thread.spawn(.{}, sleepy, .{"Two", 2, &mut, &wg});

    // Wait a little for a thread to call .start() - sometimes we get to the waitgroup
    //   here and see it empty... before any thread acquires it ...!!
    std.time.sleep(1 * std.time.ns_per_s);
    pool.waitAndWork(&wg);

    std.debug.print("Done waiting.\n", .{});
}

