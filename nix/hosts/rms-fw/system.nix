{ self, inputs, ... }:
{
  # Keep machine-only service selection separate from the shared desktop.
  flake.nixosModules.frameworkLaptop =
    { config, lib, ... }:
    let
      laptop = config.profiles.frameworkLaptop.enable;
    in
    {
      options.profiles.frameworkLaptop.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the Framework laptop's peripherals and private host services.";
      };

      config = {
        services.opencodeServer.enable = laptop;
        services.openssh.enable = laptop;
        services.tailscale.enable = laptop;
        services.fprintd.enable = laptop;
        services.hardware.bolt.enable = laptop;
        services.btrfs.autoScrub.enable = laptop;
        hardware.bluetooth.enable = laptop;
        virtualisation.libvirtd.enable = laptop;
        nix.settings.netrc-file = if laptop then "/etc/nix/netrc" else "/dev/null";

        home-manager.users.rms = {
          services.rex.enable = laptop;
          services.rex.tailscale.enable = laptop;
          programs.hyprlock.settings.auth.fingerprint.enabled = laptop;
        };
      };
    };

  flake.nixosModules.frameworkConfiguration =
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.frameworkLaptop
        inputs.disko.nixosModules.disko
        self.diskoConfigurations.hostRmsFw
        self.nixosModules.homeManager
        self.nixosModules.powerProfile
        self.nixosModules.fingerprint
        self.nixosModules.rms
        self.nixosModules.frameworkVm
        self.nixosModules.frameworkHardware
        self.nixosModules.hyprland
        self.nixosModules.tailscale
        self.nixosModules.opencodeServer
        self.nixosModules._1password
        self.nixosModules.localsend
        self.nixosModules.openlogi
        self.nixosModules.rex
      ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 10;
      boot.loader.efi.canTouchEfiVariables = true;

      zramSwap = {
        enable = true;
        memoryMax = 10 * 1024 * 1024 * 1024;
      };

      time.timeZone = "Europe/Zurich";

      networking.hostName = "rms-fw";
      networking.networkmanager.enable = true;
      networking.networkmanager.dns = "systemd-resolved";
      networking.networkmanager.wifi.powersave = true;
      networking.networkmanager.wifi.backend = "iwd";
      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 22 ];

      services.resolved.enable = true;

      # Bluetooth support
      hardware.bluetooth = {
        powerOnBoot = false;
      };

      virtualisation.podman.enable = true;
      virtualisation.podman.dockerCompat = true;

      services.btrfs.autoScrub = {
        interval = "monthly";
        fileSystems = [ "/" ];
      };
      security.polkit.enable = true;
      security.rtkit.enable = true;
      security.pki.certificateFiles = [ ./cosmos-emulator.pem ];

      services.openssh = {
        openFirewall = false;
        settings = {
          UseDns = true;
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
      services.gnome.gnome-keyring.enable = true;
      services.gnome.gcr-ssh-agent.enable = false;
      programs.ssh.startAgent = true;

      programs.nix-ld.enable = true;

      system.stateVersion = "25.05";

      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "suspend";
        # The session policy inhibits lid handling only while it owns the decision.
        # Outside that session (or after a crash), closing the lid remains safe.
        HandleLidSwitchDocked = "suspend";
      };

    };
}
