{ self, ... }:
{
  flake.nixosModules.frameworkVm = {
    # Applied only by build-vm; none of these overrides affect the laptop.
    virtualisation.vmVariant =
      { lib, pkgs, ... }:
      {
        virtualisation = {
          memorySize = 4096;
          cores = 4;
          diskSize = 20480;
          resolution = {
            x = 1440;
            y = 900;
          };
          # A virtual GPU for the Wayland desktop, without host GPU passthrough.
          qemu.options = [ "-vga virtio" ];
        };

        networking.hostName = lib.mkForce "rms-fw-vm";
        networking.wireless.iwd.enable = lib.mkForce false;
        nix.settings.netrc-file = lib.mkForce "/dev/null";

        # Public test credentials, confined to this VM. Never use them on a real host.
        users.users.rms.initialPassword = "vm";
        security.sudo.wheelNeedsPassword = false;
        services.openssh.enable = lib.mkForce false;

        # No laptop peripherals, fingerprint reader, or nested VM infrastructure.
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
        boot.extraModulePackages = lib.mkForce [ ];
        hardware.bluetooth.enable = lib.mkForce false;
        services.hardware.bolt.enable = lib.mkForce false;
        services.fwupd.enable = lib.mkForce false;
        services.fprintd.enable = lib.mkForce false;
        services.acpid.enable = lib.mkForce false;
        services.btrfs.autoScrub.enable = lib.mkForce false;
        systemd.services.fingerprint-lid-state.enable = false;
        services.udev.extraRules = lib.mkForce "";
        security.pam.services = {
          login.fprintAuth = lib.mkForce false;
          sudo.fprintAuth = lib.mkForce false;
          polkit-1.fprintAuth = lib.mkForce false;
          hyprlock.fprintAuth = lib.mkForce false;
        };
        virtualisation.libvirtd.enable = lib.mkForce false;

        # Don't enroll a test copy of this machine in the real tailnet.
        services.tailscale.enable = lib.mkForce false;
        services.opencodeServer.enable = lib.mkForce false;
        systemd.user.services.tailscale-systray.enable = false;
        home-manager.users.rms = {
          # Test the replacement only here; the laptop still imports Waybar.
          imports = [
            self.homeModules.quickshell
            self.homeModules.vmHyprlock
          ];
          programs.waybar.enable = lib.mkForce false;
          programs.waybar.systemd.enable = lib.mkForce false;
          services.rex.enable = lib.mkForce false;
          services.rex.tailscale.enable = lib.mkForce false;
          # The VM deliberately does not share the host's dotfiles checkout.
          xdg.configFile."nvim".enable = lib.mkForce false;
          xdg.configFile."ghostty".enable = lib.mkForce false;
        };
      };
  };
}
