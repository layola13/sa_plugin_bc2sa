const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const sa_bin = b.option([]const u8, "sa-bin", "Path to the SA host binary used for bc2sa install smoke tests.") orelse "sa";
    const plugin_api = b.createModule(.{
        .root_source_file = b.path("src/plugin_api.zig"),
        .target = target,
        .optimize = optimize,
    });
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/plugin.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    root_module.addImport("plugin_api", plugin_api);
    const lib = b.addLibrary(.{
        .name = "bc2sa",
        .root_module = root_module,
        .linkage = .dynamic,
    });
    b.installArtifact(lib);

    const tests = b.addTest(.{
        .root_module = root_module,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run plugin tests");
    test_step.dependOn(&run_tests.step);
    test_step.dependOn(b.getInstallStep());

    const smoke_home = b.option([]const u8, "smoke-home", "SA_PLUGINS_HOME used by the bc2sa install smoke step.") orelse b.pathJoin(&.{ ".zig-cache", "bc2sa-install-smoke-home" });
    const install_smoke_step = b.step("install-smoke", "Install bc2sa into an isolated plugin home and verify the installed command.");

    const install_smoke = b.addSystemCommand(&.{ sa_bin, "plugin", "install", "--dev", "." });
    install_smoke.setEnvironmentVariable("SA_PLUGINS_HOME", smoke_home);
    install_smoke.setEnvironmentVariable("SA_PLUGIN_DEV", "1");
    install_smoke.addFileInput(b.path("sap.json"));
    install_smoke.addFileInput(lib.getEmittedBin());
    install_smoke.step.dependOn(b.getInstallStep());
    install_smoke_step.dependOn(&install_smoke.step);

    const verify_install = b.addSystemCommand(&.{ "bash", "tests/install_smoke.sh", smoke_home, sa_bin });
    verify_install.addFileInput(b.path("tests/install_smoke.sh"));
    verify_install.addFileInput(b.path("tests/install_smoke.ll"));
    verify_install.addFileInput(b.path("sap.json"));
    verify_install.addFileInput(lib.getEmittedBin());
    verify_install.step.dependOn(&install_smoke.step);
    install_smoke_step.dependOn(&verify_install.step);
    test_step.dependOn(&verify_install.step);
}
