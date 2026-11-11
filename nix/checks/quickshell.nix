{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      host = self.nixosConfigurations.rms-fw.config.home-manager.users.rms;
      vm = self.nixosConfigurations.rms-fw.config.virtualisation.vmVariant.home-manager.users.rms;
    in
    {
      # Guard against accidentally switching the physical laptop's bar.
      checks.quickshell-isolation =
        assert host.programs.waybar.enable;
        assert !(host.systemd.user.services ? quickshell);
        assert !vm.programs.waybar.enable;
        assert !vm.programs.waybar.systemd.enable;
        assert vm.systemd.user.services ? quickshell;
        assert builtins.elem "graphical-session.target"
          vm.systemd.user.services.power-profile-session.Install.WantedBy;
        assert builtins.elem "graphical-session.target"
          vm.systemd.user.timers.power-profile-policy.Install.WantedBy;
        pkgs.runCommand "quickshell-vm-isolation" { } ''
          touch "$out"
        '';
      checks.quickshell-telemetry =
        pkgs.runCommand "quickshell-telemetry-tests" { nativeBuildInputs = [ pkgs.python3 ]; }
          ''
            export PYTHONDONTWRITEBYTECODE=1
            export PYTHONPATH=${../features/files/quickshell}
            python ${../features/files/quickshell/test_telemetry.py}
            touch "$out"
          '';
      checks.quickshell-qml = pkgs.runCommand "quickshell-qml-validation" { } ''
        cp -r ${../features/files/quickshell} qml
        chmod -R u+w qml
        cp ${vm.xdg.configFile."quickshell/faithful/Palette.qml".source} qml/Palette.qml
        ${pkgs.qt6.qtdeclarative}/bin/qmllint \
          -I ${pkgs.qt6.qtdeclarative}/lib/qt-6/qml \
          -I ${pkgs.quickshell}/lib/qt-6/qml qml/*.qml
        touch "$out"
      '';
    };
}
