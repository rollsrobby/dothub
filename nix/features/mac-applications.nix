{
  flake.homeModules.macApplications =
    { pkgs, ... }:
    {
      # User-owned Mac applications, kept separate from the CLI profile.
      home.packages = with pkgs; [
        aerospace
        iina
        vscode
      ];
    };

  # Homebrew selections are system-level options, unlike home.packages above.
  flake.darwinModules.macApplications = {
    homebrew = {
      enable = true;
      taps = [ "azure/functions" ];
      brews = [
        "azure-functions-core-tools@4"
        "bash"
        "tree-sitter-cli"
      ];
      casks = [
        "1password"
        "alfred"
        "another-redis-desktop-manager"
        "autodesk-fusion"
        "bambu-studio"
        "bartender"
        "boop"
        "ghostty"
        "homerow"
        "karabiner-elements"
        "kindavim"
        "lm-studio"
        "microsoft-outlook"
        "onedrive"
        "powershell"
        "proton-drive"
        "proton-mail"
        "proton-pass"
        "protonvpn"
        "qFlipper"
        "tailscale-app"
        "whatsapp"
        "zen"
      ];
    };
  };
}
