{ moduleWithSystem, ... }:
{
  flake.homeModules.redisTui = moduleWithSystem (
    { self', ... }:
    { pkgs, lib, ... }:
    {
      home.packages = [
        self'.packages.redis-tui
      ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.redis-tui = pkgs.stdenvNoCC.mkDerivation rec {
        pname = "redis-tui";
        version = "1.0.38";

        src = pkgs.fetchurl {
          url = "https://github.com/davidbudnick/redis-tui/releases/download/v${version}/redis-tui_${version}_Linux_x86_64.tar.gz";
          hash = "sha256-S4Jb6J3oKPg7iF1P1skas/bibJZpmMRGlNn3nb4krdE=";
        };

        sourceRoot = ".";

        installPhase = ''
          runHook preInstall

          install -Dm755 redis-tui $out/bin/redis-tui

          runHook postInstall
        '';

        meta = {
          description = "Terminal UI for Redis";
          homepage = "https://github.com/davidbudnick/redis-tui";
          license = pkgs.lib.licenses.mit;
          mainProgram = "redis-tui";
          platforms = [ "x86_64-linux" ];
        };
      };
    };
}
