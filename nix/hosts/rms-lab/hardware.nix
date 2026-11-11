{
  flake.nixosModules.rmsLabHardware = {
    # Framework workstation target; confirm the architecture/model at install.
    nixpkgs.hostPlatform = "x86_64-linux";

    # Replace this module's body with the target's generated hardware settings.
    # Do not put a raw NixOS module under nix/: import-tree expects flake-parts.
    # No disks, UUIDs, CPU generation, bootloader, or firmware are guessed here.
    assertions = [
      {
        assertion = false;
        message = "rms-lab: supply verified target hardware, filesystems and bootloader in nix/hosts/rms-lab/hardware.nix before building/installing the system.";
      }
    ];
  };
}
