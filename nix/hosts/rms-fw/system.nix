{ self, inputs, ... }:
{
  flake.nixosModules.frameworkConfiguration =
    { pkgs, ... }:
    {
      imports = [
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

      services.opencodeServer.enable = true;

      nix.settings.netrc-file = "/etc/nix/netrc";

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
      networking.wireless.iwd.enable = true;
      networking.networkmanager.wifi.backend = "iwd";
      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 22 ];

      services.resolved.enable = true;
      services.hardware.bolt.enable = true;

      # Bluetooth support
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = false;
      };

      virtualisation.podman.enable = true;
      virtualisation.podman.dockerCompat = true;

      services.fwupd.enable = true;
      services.btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
        fileSystems = [ "/" ];
      };
      security.polkit.enable = true;
      security.rtkit.enable = true;
      security.pki.certificateFiles = [ ./cosmos-emulator.pem ];

      services.openssh = {
        enable = true;
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
