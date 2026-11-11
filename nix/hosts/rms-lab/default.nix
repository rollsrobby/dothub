{ self, inputs, ... }:
{
  flake.nixosConfigurations.rms-lab = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.rmsLab ];
  };

  perSystem =
    { system, lib, ... }:
    {
      # Home can be built before the install-specific hardware is supplied.
      # Deliberately no toplevel check: hardware.nix blocks deployment for now.
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        rms-lab-home =
          self.nixosConfigurations.rms-lab.config.home-manager.users.rms.home.activationPackage;
      };
    };
}
