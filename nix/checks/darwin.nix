{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      mac = self.darwinConfigurations.rms-mbp;
      home = mac.config.home-manager.users.rms;
    in
    {
      checks.rms-mbp-evaluation =
        assert mac.pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
        assert mac.config.networking.hostName == "rms-mbp";
        assert mac.config.system.stateVersion == 5;
        assert mac.config.users.users.rms.uid == 501;
        assert home.home.homeDirectory == "/Users/rms";
        assert home.home.stateVersion == "25.05";
        assert home.programs.zsh.enable;
        # Force evaluation of both closures, but discard their string contexts:
        # a Linux check must not try to build or run a macOS system.
        pkgs.writeText "rms-mbp-evaluation.json" (
          builtins.toJSON {
            system = builtins.unsafeDiscardStringContext mac.system.drvPath;
            home = builtins.unsafeDiscardStringContext home.home.activationPackage.drvPath;
          }
        );
    };
}
