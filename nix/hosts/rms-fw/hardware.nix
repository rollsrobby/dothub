{ inputs, ... }:
{
  flake.nixosModules.frameworkHardware =
    { modulesPath, ... }:
    {
      imports = [
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      nixpkgs.hostPlatform = "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = true;
    };
}
