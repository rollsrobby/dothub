{
  flake.homeModules.rmsFwSesh =
    { config, ... }:
    let
      home = config.home.homeDirectory;
    in
    {
      programs.sesh.settings.session = [
        {
          name = "nix-config";
          path = "${home}/nix-config";
        }
        {
          name = "Database";
          path = "${home}/utils/dbui";
          startup_command = "nvim -c ':DBUIToggle'";
        }
        {
          name = "gbm";
          path = "${home}/c/gbm";
        }
        {
          name = "sml dev";
          path = "${home}/c/sml/dev";
        }
        {
          name = "sml worktree";
          path = "${home}/c/sml";
        }
        {
          name = "sml infra";
          path = "${home}/c/sml-infra-sw";
        }
        {
          name = "notes";
          path = "${home}/docs/notes";
          startup_command = "nvim .";
        }
        {
          name = "rms-pi-01";
          startup_command = "ssh rms@rms-pi-01";
          path = "${home}/";
        }
        {
          name = "http";
          path = "${home}/c/http";
        }
        {
          name = "scratchpad";
          path = "${home}/c/scratchpad/";
        }
        {
          name = "cliamp";
          startup_command = "cliamp";
        }
      ];
    };
}
