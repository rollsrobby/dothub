{
  flake.nixosModules.virtualMachines =
    { pkgs, ... }:
    {
      virtualisation.libvirtd = {
        enable = true;
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
