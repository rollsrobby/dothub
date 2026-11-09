{ moduleWithSystem, ... }:
{
  flake.homeModules.miseBrowser = moduleWithSystem (
    { self', ... }:
    { ... }:
    {
      home.packages = [ self'.packages.mise-browser ];
    }
  );

  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    lib.optionalAttrs (system == "x86_64-linux") (
      let
        pname = "mise-browser";
        version = "1.6.1";
        src = pkgs.fetchurl {
          url = "https://github.com/Rakosn1cek/Mise-browser/releases/download/v${version}/Mise.Browser-${version}.AppImage";
          hash = "sha256-LCDa7FU/P/tpdmThHAI72p7U+fWG4coIZ710VWeMYOk=";
        };
        appimageContents = pkgs.appimageTools.extract {
          inherit pname version src;
        };
      in
      {
        packages.mise-browser = pkgs.appimageTools.wrapType2 {
          inherit pname version src;

          # Expose the upstream launcher and icons outside the AppImage environment.
          extraInstallCommands = ''
            install -Dm644 ${appimageContents}/*.desktop $out/share/applications/mise-browser.desktop
            substituteInPlace $out/share/applications/mise-browser.desktop \
              --replace-fail 'Exec=AppRun' 'Exec=mise-browser'
            cp -r ${appimageContents}/usr/share/icons $out/share/
          '';

          meta = {
            description = "Keyboard-first, container-isolated web browser";
            homepage = "https://github.com/Rakosn1cek/Mise-browser";
            license = lib.licenses.gpl3Plus;
            mainProgram = pname;
            platforms = [ "x86_64-linux" ];
          };
        };
      }
    );
}
