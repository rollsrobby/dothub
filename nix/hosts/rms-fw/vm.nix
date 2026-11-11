{ self, ... }:
{
  flake.nixosModules.frameworkVm = {
    # Applied only by build-vm; none of these overrides affect the laptop.
    virtualisation.vmVariant =
      { lib, pkgs, ... }:
      {
        # No laptop peripherals or private SSH, Tailscale, Rex, or OpenCode servers.
        profiles.frameworkLaptop.enable = false;

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
        # NetworkManager's shared iwd backend otherwise enables the daemon.
        networking.wireless.iwd.enable = lib.mkForce false;

        # Public test credentials, confined to this VM. Never use them on a real host.
        users.users.rms.initialPassword = "vm";
        security.sudo.wheelNeedsPassword = false;

        # Hardware settings inherited from the upstream Framework module.
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
        boot.extraModulePackages = lib.mkForce [ ];
        # Enabled by the upstream Framework hardware module.
        services.fwupd.enable = lib.mkForce false;
        services.udev.extraRules = lib.mkForce "";
        home-manager.users.rms = {
          imports = [ self.homeModules.vmHyprlock ];
          # Keep the policy available, but do not start it automatically in the VM.
          systemd.user.services.power-profile-session.Install.WantedBy = lib.mkForce [ ];
          systemd.user.timers.power-profile-policy.Install.WantedBy = lib.mkForce [ ];
          # The VM deliberately does not share the host's dotfiles checkout.
          xdg.configFile."nvim".enable = lib.mkForce false;
          xdg.configFile."ghostty".enable = lib.mkForce false;
        };
      };
  };
}
