{
  flake.homeModules.braveOrigin =
    { config, pkgs, ... }:
    let
      teamsBravePwa = pkgs.makeDesktopItem {
        name = "teams-brave-pwa";
        desktopName = "Microsoft Teams";
        exec = ''${config.programs.chromium.finalPackage}/bin/brave-origin "--profile-directory=Profile 1" --app-id=ompifgpmddkgmclendfeacglnodjjndh %U'';
        icon = "brave-ompifgpmddkgmclendfeacglnodjjndh-Profile_1";
        mimeTypes = [
          "x-scheme-handler/web+msteams"
          "x-scheme-handler/chromium"
        ];
        startupWMClass = "crx_ompifgpmddkgmclendfeacglnodjjndh";
        categories = [
          "Network"
          "Chat"
          "Office"
        ];
      };
    in
    {
      home.packages = [
        teamsBravePwa
      ];

      programs.chromium = {
        enable = true;
        package = pkgs.brave-origin;

        extensions = [
          "hlbgchjfepnbkdeoeoehinocffkellai" # Github refined
          "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
          "ghmbeldphafepmbegfdlkpapadhbakde" # Protonpass
          "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium-c
        ];

        commandLineArgs = [
          "--disable-features=WebRtcHideLocalIpsWithMdns"
          "--enable-features=WebRTCPipeWireCapturer"
        ];
      };
    };
}
