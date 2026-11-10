{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      host = self.nixosConfigurations.rms-fw.config;
      vm = host.virtualisation.vmVariant;
    in
    {
      checks.greeter =
        # Keep both the physical host and its VM on the same single-output greeter.
        assert
          host.services.displayManager.regreet.cageArgs == [
            "-s"
            "-d"
            "-m"
            "last"
          ];
        assert vm.services.displayManager.regreet.cageArgs == host.services.displayManager.regreet.cageArgs;
        assert !host.services.displayManager.sddm.enable;
        assert !vm.services.displayManager.sddm.enable;
        # Styling must not bypass or replace the fingerprint-capable login PAM stack.
        assert host.security.pam.services.greetd.rules.auth.login.modulePath == "login";
        assert host.security.pam.services.greetd.rules.auth.login.control == "substack";
        assert host.security.pam.services.login.fprintAuth;
        assert !vm.security.pam.services.login.fprintAuth;
        pkgs.runCommand "regreet-layout"
          {
            nativeBuildInputs = [
              pkgs.cage
              pkgs.regreet
              pkgs.grim
              pkgs.python3
            ];
            FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.cantarell-fonts ]; };
          }
          ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            python3 ${../features/files/regreet/test-layout.py} \
              ${lib.escapeShellArg (toString host.environment.etc."greetd/regreet.toml".source)} \
              ${lib.escapeShellArg (toString host.environment.etc."greetd/regreet.css".source)}
            touch "$out"
          '';
    };
}
