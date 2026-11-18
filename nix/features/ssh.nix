{ ... }:
{
  flake.homeModules.ssh =
    { config, ... }:
    let
      sshDir = "${config.home.homeDirectory}/.ssh";
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."github.com" = {
          Hostname = "github.com";
          User = "git";
          IdentityFile = "${sshDir}/id_ed25519_dev";
          IdentitiesOnly = true;
          AddKeysToAgent = "yes";
        };
      };
    };
}
