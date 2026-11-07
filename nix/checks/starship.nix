{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      linux = self.nixosConfigurations.rms-fw.config.home-manager.users.rms;
      mac = self.darwinConfigurations.rms-mbp.config.home-manager.users.rms;
      expected = pkgs.writeText "starship-settings.json" (
        builtins.toJSON linux.programs.starship.settings
      );
      generated = linux.home.file.${linux.programs.starship.configPath}.source;
    in
    {
      checks.starship =
        assert linux.programs.starship.settings == mac.programs.starship.settings;
        assert linux.programs.starship.validateFiles.config && mac.programs.starship.validateFiles.config;
        assert linux.programs.starship.enableFishIntegration;
        assert linux.programs.starship.enableZshIntegration && mac.programs.starship.enableZshIntegration;
        assert !(mac.home.file ? ".config/starship.toml");
        # Evaluate the Mac's generated config without building Darwin binaries on Linux.
        assert mac.home.file.${mac.programs.starship.configPath}.enable;
        pkgs.runCommand "shared-starship"
          {
            nativeBuildInputs = [
              pkgs.python3
              pkgs.git
              linux.programs.starship.package
            ];
          }
          ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            export STARSHIP_CONFIG=${generated}
            python3 - ${expected} "$STARSHIP_CONFIG" <<'PY'
            import json
            import re
            import subprocess
            import sys
            import tempfile
            import tomllib
            from pathlib import Path

            # Verify the generated, schema-validated TOML matches our Nix settings.
            with open(sys.argv[1]) as file:
                expected = json.load(file)
            with open(sys.argv[2], "rb") as file:
                generated = tomllib.load(file)
            assert generated == expected

            def render(module, *args, cwd=None):
                # Supply logical and physical paths explicitly: subprocess cwd
                # alone does not update the inherited shell's PWD variable.
                paths = ["--path", str(cwd), "--logical-path", str(cwd)] if cwd else []
                result = subprocess.run(
                    ["starship", "module", module, *paths, *args], cwd=cwd,
                    text=True, capture_output=True, check=True,
                )
                assert not result.stderr.strip(), result.stderr
                return re.sub(r"\x1b\[[0-9;]*m", "", result.stdout)

            for status, symbol in [("0", "➜"), ("1", "✗")]:
                assert symbol in render("character", "--status", status)
            assert render("cmd_duration", "--cmd-duration", "2000").strip() == ""
            assert "5s" in render("cmd_duration", "--cmd-duration", "5000")

            # A local-only repository exercises the actual Git format strings.
            # Disable signing/hooks inside this fixture; no user keys or network needed.
            with tempfile.TemporaryDirectory() as directory:
                repo = Path(directory)
                def git(*args):
                    subprocess.run(["git", *args], cwd=repo, check=True,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                git("init", "--initial-branch=main")
                git("config", "user.name", "Prompt Test")
                git("config", "user.email", "test@example.invalid")
                git("config", "commit.gpgsign", "false")
                git("config", "core.hooksPath", "/dev/null")
                git("commit", "--allow-empty", "-m", "base")
                git("branch", "upstream")
                git("branch", "--set-upstream-to=upstream", "main")
                git("commit", "--allow-empty", "-m", "local")
                git("checkout", "upstream")
                git("commit", "--allow-empty", "-m", "other")
                git("checkout", "main")
                (repo / "untracked.txt").write_text("test")
                status = render("git_status", cwd=repo)
                assert "?1" in status, status
                assert "⇕⇡1⇣1" in status, status
                (repo / "package.json").write_text('{"name":"test","version":"1.2.3"}')
                # `starship module` intentionally renders disabled modules too.
                # Prove the fixture is detected, then check the real full prompt.
                assert "1.2.3" in render("package", cwd=repo)
                prompt = subprocess.run(
                    ["starship", "prompt"], cwd=repo,
                    text=True, capture_output=True, check=True,
                )
                assert not prompt.stderr.strip(), prompt.stderr
                assert "1.2.3" not in prompt.stdout, prompt.stdout
                git("stash", "push", "--include-untracked", "--message", "fixture")
                assert "$1" in render("git_status", cwd=repo)
                deep = repo / "one/two/three/four"
                deep.mkdir(parents=True)
                directory = render("directory", cwd=deep)
                assert "…/" not in directory, directory
                assert "two/three/four" in directory, directory
                assert "one/two/three/four" not in directory, directory
            print("PASS: Nix/TOML parity, characters, duration, Git/stash counts, paths and package visibility")
            PY
            touch "$out"
          '';
    };
}
