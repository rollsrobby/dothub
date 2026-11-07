{ self, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      host = self.nixosConfigurations.rms-fw;
      linux = host.config.home-manager.users.rms;
      mac = self.darwinConfigurations.rms-mbp.config.home-manager.users.rms;
      zshProbe =
        (host.extendModules {
          modules = [
            { home-manager.users.rms.programs.zsh.shellAliases.__zsh_only_probe = "not-for-fish"; }
          ];
        }).config.home-manager.users.rms;
      programs = [
        "atuin"
        "bat"
        "btop"
        "direnv"
        "eza"
        "fd"
        "fzf"
        "gh"
        "gh-dash"
        "git"
        "jq"
        "ripgrep"
        "starship"
        "yazi"
        "zoxide"
        "zsh"
      ];
    in
    {
      checks.cli =
        assert lib.all (name: linux.programs.${name}.enable && mac.programs.${name}.enable) programs;
        assert linux.home.shellAliases == mac.home.shellAliases;
        assert linux.programs.zsh.shellAliases == mac.programs.zsh.shellAliases;
        assert lib.all (name: linux.programs.fish.shellAliases.${name} == linux.home.shellAliases.${name}) (
          builtins.attrNames linux.home.shellAliases
        );
        assert linux.home.shellAliases.gs == "gh stack";
        assert !builtins.hasAttr "__zsh_only_probe" zshProbe.programs.fish.shellAliases;
        assert linux.programs.atuin.settings == mac.programs.atuin.settings;
        assert linux.programs.atuin.flags == mac.programs.atuin.flags;
        assert linux.programs.git.settings.user == mac.programs.git.settings.user;
        assert linux.programs.git.settings.alias == mac.programs.git.settings.alias;
        assert linux.programs.git.signing.key == mac.programs.git.signing.key;
        assert linux.programs.git.signing.signByDefault && mac.programs.git.signing.signByDefault;
        assert linux.programs.gh.settings == mac.programs.gh.settings;
        assert map lib.getName linux.programs.gh.extensions == map lib.getName mac.programs.gh.extensions;
        assert linux.programs.gh-dash.settings == mac.programs.gh-dash.settings;
        assert builtins.isList linux.programs.gh-dash.settings.keybindings.prs;
        assert linux.programs.fzf.defaultCommand == mac.programs.fzf.defaultCommand;
        assert linux.programs.fzf.historyWidget.command == mac.programs.fzf.historyWidget.command;
        assert !lib.hasInfix "gs shell completion" mac.programs.zsh.initContent;
        assert lib.all
          (
            c:
            lib.hasInfix "bind-atuin-history" c.programs.zsh.initContent
            && lib.hasInfix "function sesh-sessions()" c.programs.zsh.initContent
          )
          [
            linux
            mac
          ];
        assert linux.home.sessionVariables.EDITOR == mac.home.sessionVariables.EDITOR;
        assert linux.home.sessionVariables.PAGER == mac.home.sessionVariables.PAGER;
        assert lib.all (c: lib.hasSuffix "/bin/bat -plman" c.home.sessionVariables.MANPAGER) [
          linux
          mac
        ];
        pkgs.runCommand "shared-cli" { nativeBuildInputs = [ pkgs.fish ]; } ''
          # Exercise Home Manager's generated Fish environment. macOS parity is
          # checked by evaluation above; no macOS binaries run in a Linux build.
          fish --no-config -c '
            for name in EDITOR PAGER MANPAGER __HM_SESS_VARS_SOURCED
              set --erase $name
            end
            source ${linux.programs.fish.sessionVariablesPackage}/etc/profile.d/hm-session-vars.fish
            test "$EDITOR" = nvim; or exit 1
            test "$PAGER" = "less -FirSwX"; or exit 1
            test "$MANPAGER" = "${pkgs.bat}/bin/bat -plman"; or exit 1
          '
          touch "$out"
        '';
    };
}
