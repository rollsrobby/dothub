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
        pkgs.runCommand "quickshell-vm-isolation" { } ''
          touch "$out"
        '';
    };
}
