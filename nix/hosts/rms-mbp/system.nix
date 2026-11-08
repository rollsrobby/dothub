{ self, ... }:
{
  flake.darwinModules.rmsMbp =
    { pkgs, ... }:
    {
      imports = [
        self.darwinModules.nixPolicy
        self.nixosModules.homeManager
      ];

      system.primaryUser = "rms";
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
      networking.hostName = "rms-mbp";

      security.pam.services.sudo_local.touchIdAuth = true;
      system.defaults = {
        NSGlobalDomain = {
          AppleShowAllExtensions = true;
          InitialKeyRepeat = 15;
          KeyRepeat = 1;
          NSAutomaticSpellingCorrectionEnabled = false;
          "com.apple.mouse.tapBehavior" = 1;
          "com.apple.swipescrolldirection" = false;
        };
        controlcenter.BatteryShowPercentage = true;
        dock = {
          orientation = "right";
          persistent-apps = [ ];
          tilesize = 32;
          largesize = 36;
          magnification = true;
          autohide = true;
          show-recents = false;
          mru-spaces = false;
          expose-group-apps = true;
        };
        spaces.spans-displays = true;
        smb.NetBIOSName = "rms-mbp";
        trackpad.Clicking = true;
        finder = {
          _FXSortFoldersFirst = true;
          FXPreferredViewStyle = "Nlsv";
          AppleShowAllExtensions = true;
          ShowPathbar = true;
          ShowStatusBar = true;
          ShowRemovableMediaOnDesktop = false;
          ShowExternalHardDrivesOnDesktop = false;
          NewWindowTarget = "Home";
        };
        WindowManager.EnableStandardClickToShowDesktop = false;
      };

      fonts.packages = with pkgs; [
        nerd-fonts.geist-mono
        nerd-fonts.monaspace
      ];

      system.configurationRevision = self.rev or self.dirtyRev or null;
      # Preserve the Mac's existing compatibility version during migration.
      system.stateVersion = 5;

      users.users.rms = {
        home = "/Users/rms";
        uid = 501;
      };
      users.knownUsers = [ "rms" ];
    };
}
