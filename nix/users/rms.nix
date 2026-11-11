{
  flake.nixosModules.rms = { pkgs, ... }: {
    users.users.rms = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [
        "wheel"
        "networkmanager"
        "bluetooth"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKkZoBxA/dL/xV+tDuq/DdRB9ddxefkwQht/DnjtAGd5" # mobile phone
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvy5+JkkYU7awyfZWIplp3YSvk6HPKzd4EZP/R7Un4o rms-fw"
      ];
    };
  };
}
