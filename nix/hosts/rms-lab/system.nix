{ self, ... }:
{
  flake.nixosModules.rmsLab =
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.rmsLabHardware
        self.nixosModules.homeManager
        self.nixosModules.rms
        self.nixosModules.nixPolicy
        self.nixosModules.unfree
        self.nixosModules.fish
        self.nixosModules.zsh
        self.nixosModules.rex
        self.nixosModules.opencodePackage
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
    };
}
