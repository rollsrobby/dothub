{ self, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      linuxHost = self.nixosConfigurations.rms-fw;
      macHost = self.darwinConfigurations.rms-mbp;
      linux = linuxHost.config.home-manager.users.rms;
      mac = macHost.config.home-manager.users.rms;
      linuxSystem = linuxHost.config.environment.systemPackages;
      macSystem = macHost.config.environment.systemPackages;
      occurrences = package: packages: lib.count (p: p.drvPath == package.drvPath) packages;
      shared = [
        "azurite"
        "cargo"
        "devenv"
        "git-spice"
        "lazydocker"
        "lua-language-server"
        "neovim"
        "ngrok"
        "nil"
        "nix-search-tv"
        "nixd"
        "nixfmt"
        "ollama"
        "tmuxp"
        "tombi"
        "tuicr"
        "unar"
        "yq"
      ];
      moduleOwned = [
        "bat"
        "btop"
        "fd"
        "fzf"
        "git"
        "lazygit"
        "sesh"
        "tmux"
      ];
      uniqueHomePackages =
        hostPkgs: home: names:
        lib.all (name: occurrences hostPkgs.${name} home.home.packages == 1) names;
      noSystemCopies =
        hostPkgs: packages: lib.all (name: occurrences hostPkgs.${name} packages == 0) shared;
    in
    {
      checks.cli-packages =
        assert uniqueHomePackages linuxHost.pkgs linux (shared ++ moduleOwned);
        assert uniqueHomePackages macHost.pkgs mac (shared ++ moduleOwned);
        assert noSystemCopies linuxHost.pkgs linuxSystem;
        assert noSystemCopies macHost.pkgs macSystem;
        assert occurrences linuxHost.pkgs.btop linuxSystem == 0;
        # Do not replace Podman's docker command or introduce a Docker daemon on Linux.
        assert linuxHost.config.virtualisation.podman.enable;
        assert linuxHost.config.virtualisation.podman.dockerCompat;
        assert !linuxHost.config.virtualisation.docker.enable;
        assert occurrences linuxHost.pkgs.docker linux.home.packages == 0;
        assert occurrences macHost.pkgs.docker mac.home.packages == 1;
        assert occurrences macHost.pkgs.colima mac.home.packages == 1;
        # Core process tools and the 1Password integration have platform-specific owners.
        assert occurrences linuxHost.pkgs.procps linuxSystem == 1;
        assert occurrences linuxHost.pkgs.procps linux.home.packages == 0;
        assert occurrences macHost.pkgs.procps mac.home.packages == 1;
        assert linuxHost.config.programs._1password.enable;
        assert linuxHost.config.programs._1password-gui.enable;
        assert occurrences linuxHost.pkgs._1password-cli linuxSystem == 1;
        assert occurrences linuxHost.pkgs._1password-cli linux.home.packages == 0;
        assert occurrences macHost.pkgs._1password-cli mac.home.packages == 1;
        # Tmux, sesh, and lazygit are managed on both hosts.
        assert mac.programs.tmux.enable && mac.programs.sesh.enable && mac.programs.lazygit.enable;
        assert !(mac.home.file ? ".config/tmux");
        assert !(mac.home.file ? ".config/sesh");
        pkgs.writeText "cli-package-ownership.json" (
          builtins.toJSON {
            sharedTools = shared;
            moduleOwnedTools = moduleOwned;
            linux = linuxHost.pkgs.stdenv.hostPlatform.system;
            mac = macHost.pkgs.stdenv.hostPlatform.system;
          }
        );
    };
}
