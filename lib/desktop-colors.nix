# Semantic roles, with the existing desktop variants kept intentionally distinct.
# Pure data lives outside nix/, whose .nix files are auto-imported as modules.
{
  bar = {
    text = "cdd6f4";
    surface = "181824";
    menuSurface = "161320";
    danger = "f7768e";
    warning = "e0af68";
    selection = "7aa2f7";
    workspaceActive = "ad8ee6";
    accent = "0db9d7";
  };

  notifications = {
    surface = "0f172a";
    surfaceDim = "111827";
    surfaceHover = "1e293b";
    surfacePressed = "334155";
    text = "e2e8f0";
    textMuted = "94a3b8";
    accent = "08b4ff";
    danger = "fb7185";
    dangerSurface = "3f1d2e";
  };

  greeter = {
    background = "101318";
    backgroundEnd = "1b222b";
    text = "e5e9ef";
    surface = "20262e";
    border = "39424e";
    input = "131920";
    inputBorder = "414c5a";
    focus = "a9bdd0";
    action = "d5dfe8";
    actionText = "17202a";
    actionHover = "edf2f7";
    secondary = "303842";
    secondaryBorder = "4a5664";
  };

  lock = {
    border = "505869";
    surface = "181c24";
    text = "eaecf2";
    textMuted = "d8dee9";
    danger = "e05656";
  };
}
