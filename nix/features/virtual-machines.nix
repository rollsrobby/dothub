{
  flake.nixosModules.virtualMachines =
    { lib, pkgs, ... }:
    {
      virtualisation.libvirtd = {
        enable = lib.mkDefault true;
        qemu.runAsRoot = false;
      };

      programs.virt-manager.enable = true;

      users.users.rms.extraGroups = [
        "libvirtd"
      ];

      environment.systemPackages = with pkgs; [
        libvirt # virsh
        virt-top
      ];
    };
}
