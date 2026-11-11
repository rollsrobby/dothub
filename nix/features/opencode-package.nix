{
  # Used by both headless and desktop hosts, for the CLI and system server.
  flake.nixosModules.opencodePackage = {
    nixpkgs.overlays = [
      (_: prev: {
        opencode = prev.opencode.overrideAttrs (old: {
          node_modules = old.node_modules.overrideAttrs (_: {
            outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
          });
        });
      })
    ];
  };
}
