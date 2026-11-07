{
  # Behavior is shared; each host supplies its own sessions and project roots.
  flake.homeModules.sesh = {
    programs.sesh = {
      enable = true;
      enableAlias = false;
      enableTmuxIntegration = true;
      # The shared CLI's programs.zoxide already installs this binary.
      zoxidePackage = null;
      tmuxKey = "o";
    };
  };
}
