const std = @import("std");
const calm_file = @embedFile("music/Calm.mp3");
const combat_file = @embedFile("music/Combat.mp3");

const libinput = @import("libinput");
const rl = @cImport({
    @cInclude("raylib.h");
});

var run = true;

pub fn sigintHandler(_: c_int, _: *const std.os.siginfo_t, _: ?*const anyopaque) callconv(.C) void {
    run = false;
}

pub fn main() !void {
    const act = std.os.Sigaction{
        .handler = .{
            .sigaction = sigintHandler,
        },
        .mask = std.os.empty_sigset,
        .flags = 0,
    };
    try std.os.sigaction(std.os.SIG.INT, &act, null);

    rl.InitAudioDevice();
    defer rl.CloseAudioDevice();

    var calm = rl.LoadMusicStreamFromMemory(".mp3", calm_file, calm_file.len);
    defer rl.UnloadMusicStream(calm);
    var combat = rl.LoadMusicStreamFromMemory(".mp3", combat_file, combat_file.len);
    defer rl.UnloadMusicStream(combat);

    rl.PlayMusicStream(calm);
    rl.PlayMusicStream(combat);

    var calm_vol: f32 = 1;
    var combat_vol: f32 = 0;

    var li = try libinput.init(.{ .udev = .{} }, null);
    defer li.deinit();

    var vol_key_held = false;

    while (run) {
        calm_vol = std.math.clamp(calm_vol, 0, 0.4);
        combat_vol = std.math.clamp(combat_vol, 0, 0.4);

        // Handle libinput
        try li.dispatch();

        if (li.get(.event)) |*event| {
            defer event.destroy();
            if (event.kind() == .keyboard_key) {
                const ev = event.get_event();
                switch (ev.keyboard.key) {
                    26 => return,
                    27 => {
                        if (ev.keyboard.state == .pressed) vol_key_held = true else vol_key_held = false;
                    },
                    else => {},
                }
            }
        }

        rl.UpdateMusicStream(calm);
        rl.UpdateMusicStream(combat);

        rl.SetMusicVolume(calm, calm_vol);
        rl.SetMusicVolume(combat, combat_vol);

        if (vol_key_held) combat_vol += 0.01 else combat_vol -= 0.01;

        std.time.sleep(std.time.ns_per_s / 60);
    }
}
