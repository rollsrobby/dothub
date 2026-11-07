{ moduleWithSystem, ... }:
{
  flake.homeModules.whatsapp = moduleWithSystem (
    { self', ... }:
    { pkgs, lib, ... }:
    {
      home.packages = [
        pkgs.microsoft-edge
        self'.packages.whatsapp-pwa
      ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.whatsapp-pwa = pkgs.makeDesktopItem {
        name = "whatsapp-pwa";
        desktopName = "WhatsApp Web";
        exec = "${pkgs.microsoft-edge}/bin/microsoft-edge --app=https://web.whatsapp.com/";
        icon = "microsoft-edge";
        categories = [
          "Network"
          "Chat"
        ];
      };
    };
}
