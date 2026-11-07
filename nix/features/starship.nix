{
  flake.homeModules.starship = {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      # Validate generated TOML against the schema shipped with this Starship version.
      validateFiles.config = true;

      settings = {
        add_newline = true;
        # Retain automatic language/tool detection instead of maintaining a fixed list.
        format = "$all";

        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };

        directory = {
          # Keep long paths readable while retaining repository context.
          truncation_length = 3;
          truncate_to_repo = true;
          truncation_symbol = "";
          style = "bold cyan";
        };

        # Runtime modules already show useful project information; omit package versions.
        package.disabled = true;

        git_status = {
          conflicted = "[=($count)](fg:#FF75D8)";
          stashed = "[\\$($count)](fg:#29A0B1)";
          ahead = "[⇡($count)](fg:#B5E5CF)";
          behind = "[⇣($count)](fg:#FCB5AC)";
          diverged = "[⇕⇡$ahead_count⇣$behind_count](fg:#FCB5AC)";
          # The old dark green was difficult to read on dark terminal backgrounds.
          untracked = "[?($count)](fg:#89B4FA)";
          modified = "[!($count)](fg:#FBE7C6)";
          staged = "[+($count)](fg:#B4F8C8)";
          renamed = "[»($count)](fg:#B99095)";
          deleted = "[✘($count)](fg:#FFAEBC)";
        };

        cmd_duration = {
          # Keep fast commands quiet; show elapsed time for commands taking >= 3s.
          min_time = 3000;
          format = "took [$duration](bold yellow) ";
        };

        # Preserve context visibility: Docker stays file-sensitive, Kubernetes
        # remains visible when configured rather than being hidden outside a project.
        docker_context = {
          format = "via [🐋 $context ](blue bold)";
          only_with_files = true;
          disabled = false;
        };
        kubernetes.disabled = false;
        direnv.disabled = false;
        dotnet = {
          disabled = false;
          style = "bold green";
        };
      };
    };
  };
}
