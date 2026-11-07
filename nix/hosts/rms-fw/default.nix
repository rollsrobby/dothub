{ self, inputs, ... }:
{
  flake.nixosConfigurations.rms-fw = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.frameworkConfiguration
      self.nixosModules.base
      self.nixosModules.packages
      { home-manager.users.rms = self.homeModules.rmsFw; }
      self.nixosModules.virtualMachines
    ];
  };

  perSystem =
    { system, lib, ... }:
    let
      host = self.nixosConfigurations.rms-fw;
    in
    {
      # A short build target for the same ReGreet VM used by build-vm.
      packages = lib.optionalAttrs (system == host.pkgs.stdenv.hostPlatform.system) {
        vm = host.config.system.build.vm;
      };

      # Do not schedule this host's checks on incompatible architectures.
      checks = lib.optionalAttrs (system == host.pkgs.stdenv.hostPlatform.system) {
        framework = host.config.system.build.toplevel;
        framework-home = host.config.home-manager.users.rms.home.activationPackage;
        framework-vm = host.config.system.build.vm;
      };
    };
}
