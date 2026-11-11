{ moduleWithSystem, ... }:
{
  # Opt-in preview: only the VM imports this module alongside the shared hyprlock layout.
  flake.homeModules.vmHyprlock = moduleWithSystem (
    { config, ... }:
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "preview-lock";
          text = ''
            if [[ -z "''${WAYLAND_DISPLAY:-}" ]]; then
              echo "Run preview-lock from a terminal in the VM's Hyprland session." >&2
              exit 1
            fi
            exec ${config.packages.idle-policy}/bin/idle-policy lock
          '';
        })
      ];

    }
  );
}
