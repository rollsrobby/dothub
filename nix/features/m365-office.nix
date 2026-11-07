{ moduleWithSystem, ... }:
{
  flake.nixosModules.m365-office = moduleWithSystem (
    { self', ... }:
    { pkgs, lib, ... }:
    {
      environment.systemPackages = [
        pkgs.microsoft-edge
        self'.packages.outlook-pwa
      ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.outlook-pwa = pkgs.makeDesktopItem {
        name = "outlook-pwa";
        desktopName = "Microsoft Outlook";
        exec = "${pkgs.microsoft-edge}/bin/microsoft-edge --app=https://outlook.office365.com/";
        icon = "microsoft-edge";
        categories = [
          "Network"
          "Chat"
          "Office"
        ];
      };
    };
}
