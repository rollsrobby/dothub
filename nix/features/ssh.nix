{ ... }:
{
  flake.homeModules.ssh = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."github.com" = {
        Hostname = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      settings."*" = {
        IdentityAgent = "~/.1password/agent.sock";
      };
    };
  };
}
