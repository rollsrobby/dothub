{ moduleWithSystem, self, ... }:
{
  flake.nixosModules.packages = moduleWithSystem (
    { self', inputs', ... }:
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.unfree
      ];

      # Share the dependency-hash correction between the CLI and system server.
      nixpkgs.overlays = [
        (_: prev: {
          opencode = prev.opencode.overrideAttrs (old: {
            node_modules = old.node_modules.overrideAttrs (_: {
              outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
            });
          });
        })
      ];

      # Desktop and host-administration tools only. Shared CLI packages live in
      # homeModules.cli; 1Password and core process tools have dedicated owners.
      environment.systemPackages = with pkgs; [
        kitty
        alsa-utils
        bibata-cursors
        brightnessctl
        dnsutils
        gcc
        ghostty
        hyprshutdown
        nautilus
        networkmanager
        networkmanagerapplet
        pavucontrol
        pwvucontrol
        proton-pass
        sushi
        usbutils
        inputs'.helium.packages.default
        self'.packages.tree-sitter
        inputs'.zen-browser.packages.default
      ];
    }
  );

  flake.homeModules.packages =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        cliamp
        dotnet-sdk_10
        easyeffects
        fastfetch
        proton-vpn
        protonmail-desktop
        speedtest-cli
        spotify
        typescript
        vlc
      ];
    };
}
