{ inputs, ... }:
{
  flake.nixosModules.rex = {
    # Start rms's user services at boot and keep them running after logout.
    users.users.rms.linger = true;
  };

  flake.homeModules.rex = { lib, ... }: {
    imports = [ inputs.rex.homeManagerModules.default ];

    # Install Rex and its terminal/SSH integration for rms.
    programs.rex.enable = true;
    programs.ssh.enable = true;

    # Run terminals as rms, with rms's home and application configuration.
    services.rex = {
      enable = lib.mkDefault true;
      tailscale = {
        enable = lib.mkDefault true;
        hostname = "rex-rms-fw";
      };
    };
  };
}
