let
  # Shared policy; scheduling belongs to the platform-specific modules below.
  policy = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };
in
{
  flake.nixosModules.nixPolicy = {
    imports = [ policy ];
    nix.gc = {
      dates = "weekly";
      persistent = true;
    };
  };

  flake.darwinModules.nixPolicy = {
    imports = [ policy ];
    # launchd's weekly schedule: Sunday at 03:15 local time.
    nix.gc.interval = [
      {
        Weekday = 7;
        Hour = 3;
        Minute = 15;
      }
    ];
  };
}
