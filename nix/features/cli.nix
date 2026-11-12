{ self, ... }:
{
  flake.homeModules.cli =
    {
      pkgs,
      ...
    }:
    let
      gitCloneBareForWorktrees = pkgs.writeShellScriptBin "git-clone-bare-for-worktrees" ''
        set -e

        # as seen on https://morgan.cugerone.com/blog/workarounds-to-git-worktree-using-bare-repository-and-cannot-fetch-remote-branches

        # Examples of call:
        # git-clone-bare-for-worktrees git@github.com:name/repo.git
        # => Clones to a /repo directory
        #
        # git-clone-bare-for-worktrees git@github.com:name/repo.git my-repo
        # => Clones to a /my-repo directory

        url=$1
        basename=''${url##*/}
        name=''${2:-''${basename%.*}}

        mkdir "$name"
        cd "$name"

        # Moves all the administrative git files (a.k.a $GIT_DIR) under .bare directory.
        #
        # Plan is to create worktrees as siblings of this directory.
        # Example targeted structure:
        # .bare
        # main
        # new-awesome-feature
        # hotfix-bug-12
        # ...
        git clone --bare "$url" .bare
        printf 'gitdir: ./.bare\n' > .git

        # Explicitly sets the remote origin fetch so we can fetch remote branches
        git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

        # Gets all branches from origin
        git fetch origin
      '';
    in
    {
      imports = [
        self.homeModules.starship
        self.homeModules.tmux
        self.homeModules.sesh
        self.homeModules.lazygit
      ];

      # Home Manager distributes these aliases and variables to each enabled shell.
      # Neither Fish nor the Mac profile needs to read another shell's options.
      home.shellAliases = {
        n = "nvim";
        "n." = "nvim .";
        e = "exit";
        c = "clear";
        p = "pnpm";
        b = "bun";
        k = "kubectl";
        d = "docker";
        ".." = "cd ..";
        "...." = "cd ../..";
        "......" = "cd ../../..";
        grep = "grep --color=auto";
        cat = "bat";
        ll = "eza --icons --git --long --all";
        ls = "eza --icons --git --long";
        oc = "opencode .";
        sml = "tmuxp load ~/.tmuxp/sml.yaml -a";
        tks = "tmux kill-server";
        gs = "gh stack";
      };
      home.sessionVariables = {
        EDITOR = "nvim";
        PAGER = "less -FirSwX";
        MANPAGER = "${pkgs.bat}/bin/bat -plman";
      };

      # Portable developer tools belong to the user's CLI profile, not a system
      # package bag. Programs enabled below already install their own binaries.
      home.packages = [
        gitCloneBareForWorktrees
      ]
      ++ (with pkgs; [
        azurite
        cargo
        devenv
        git-spice
        lazydocker
        lua-language-server
        neovim
        ngrok
        nil
        nix-search-tv
        nixd
        nixfmt
        ollama
        tmuxp
        tombi
        tuicr
        unar
        yq
      ]);

      programs = {
        bat.enable = true;
        fd.enable = true;
        jq.enable = true;
        ripgrep.enable = true;
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        eza = {
          enable = true;
          enableZshIntegration = true;
        };
        yazi = {
          enable = true;
          enableZshIntegration = true;
          shellWrapperName = "y";
        };
        zoxide = {
          enable = true;
          options = [ "--cmd cx" ];
        };
        btop.enable = true;

        zsh = {
          enable = true;
          enableCompletion = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          initContent = ''
            source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
            # zsh-vi-mode initializes lazily and otherwise resets Ctrl+R.
            bind-atuin-history() {
              bindkey -M emacs '^R' atuin-search
              bindkey -M viins '^R' atuin-search-viins
              bindkey -M vicmd '^R' atuin-search-vicmd
            }
            zvm_after_init_commands+=(bind-atuin-history)
            zvm_after_lazy_keybindings_commands+=(bind-atuin-history)

            eval "$(${pkgs.devenv}/bin/devenv hook zsh)"
            h() { "$@" --help 2>&1 | bat -l help -p --paging=never; }
            # Fuzzy-search nixpkgs and put `nix shell nixpkgs#<attr>` on the command line.
            ns() {
              local attr
              # Only the nixpkgs index (installable packages), not NixOS/home-manager options.
              attr=$(nix-search-tv print --indexes nixpkgs \
                | fzf --preview 'nix-search-tv preview {}' --scheme history \
                | awk '{print $2}')
              [[ -z "$attr" ]] && return
              # print -z pushes text into the edit buffer without running it.
              print -z "nix shell nixpkgs#$attr"
            }
            function sesh-sessions() {
              {
                exec </dev/tty
                exec <&1
                local session
                session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '> ')
                zle reset-prompt > /dev/null 2>&1 || true
                [[ -z "$session" ]] && return
                sesh connect $session
              }
            }

            zle -N sesh-sessions
            bindkey -M emacs '\es' sesh-sessions
            bindkey -M vicmd '\es' sesh-sessions
            bindkey -M viins '\es' sesh-sessions
          '';
        };
        git = {
          enable = true;
          ignores = [
            ".direnv/"
          ];
          settings = {
            user.name = "rollsrobby";
            user.email = "30313644+rollsrobby@users.noreply.github.com";
            alias = {
              clone-for-worktrees = "!git-clone-bare-for-worktrees";
            };
          };
          signing = {
            key = "~/.ssh/id_ed25519.pub";
            format = "ssh";
            signByDefault = true;
          };
        };

        atuin = {
          enable = true;
          enableZshIntegration = true;
          flags = [ "--disable-up-arrow" ];
          settings = {
            auto_sync = false;
            update_check = false;
          };
        };

        fzf = {
          enable = true;
          enableZshIntegration = true;
          tmux.enableShellIntegration = true;
          historyWidget.command = "";
        };

        gh = {
          enable = true;
          extensions = with pkgs; [
            gh-stack
            gh-poi
          ];
        };
        gh-dash = {
          enable = true;
          settings = {
            defaults.merge.deleteBranch = false;
            # gh-dash expects a list of bindings, not an attribute set.
            keybindings.prs = [
              {
                key = "M";
                command = "gh pr merge --merge {{.PrNumber}} --repo {{.RepoName}}";
                name = "Merge with create commit";
                confirm = true;
              }
            ];
          };
        };
      };
    };
}
