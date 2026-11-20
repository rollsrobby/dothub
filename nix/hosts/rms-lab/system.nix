{ self, inputs, ... }:
{
  flake.nixosModules.rmsLab =
    { pkgs, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        self.nixosModules.rmsLabHardware
        self.diskoConfigurations.hostRmsLab
        self.nixosModules.homeManager
        self.nixosModules.rms
        self.nixosModules.nixPolicy
        self.nixosModules.unfree
        self.nixosModules.fish
        self.nixosModules.zsh
        self.nixosModules.rex
        self.nixosModules.opencodeServer
      ];

      networking.hostName = "rms-lab";
      networking.networkmanager.enable = true;
      networking.networkmanager.dns = "systemd-resolved";
      services.resolved.enable = true;
      time.timeZone = "Europe/Zurich";

      services.tailscale.enable = true;
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
      services.openssh = {
        enable = true;
        openFirewall = false;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
      programs.ssh.startAgent = true;
      programs.nix-ld.enable = true;
      programs._1password.enable = true;
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
      };
      environment.systemPackages = with pkgs; [
        gcc
        dnsutils
        usbutils
      ];

      services.opencodeServer.enable = true;
      home-manager.users.rms = self.homeModules.rmsLab;
      system.stateVersion = "26.05";
      services.fwupd.enable =  true;

      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 10;
      boot.loader.efi.canTouchEfiVariables = true;
    };
}
