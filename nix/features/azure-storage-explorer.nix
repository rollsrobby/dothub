{ moduleWithSystem, ... }:
{
  flake.homeModules.azureStorageExplorer = moduleWithSystem (
    { self', ... }:
    { ... }:
    {
      home.packages = [
        self'.packages.azure-storage-explorer
      ];
    }
  );

  perSystem =
    { pkgs, ... }:
    let
      version = "1.46.0";

      unwrapped = pkgs.stdenvNoCC.mkDerivation {
        pname = "azure-storage-explorer-unwrapped";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/microsoft/AzureStorageExplorer/releases/download/v${version}/StorageExplorer-linux-x64.tar.gz";
          hash = "sha256-qSdc0df2Pt27qGQByQZogDUAsuwQskEmoKhpbmeqnaU=";
        };

        sourceRoot = ".";
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/azure-storage-explorer
          cp -r . $out/lib/azure-storage-explorer

          runHook postInstall
        '';
      };

      desktopItem = pkgs.makeDesktopItem {
        name = "azure-storage-explorer";
        desktopName = "Microsoft Azure Storage Explorer";
        comment = "Manage Azure Storage resources";
        exec = "azure-storage-explorer %U";
        icon = "azure-storage-explorer";
        categories = [ "Development" ];
        startupWMClass = "Microsoft Azure Storage Explorer";
      };
    in
    {
      packages.azure-storage-explorer = pkgs.buildFHSEnv {
        pname = "azure-storage-explorer";
        inherit version;

        targetPkgs =
          pkgs': with pkgs'; [
            alsa-lib
            at-spi2-core
            cairo
            cups
            dbus
            dotnet-runtime_10
            expat
            fontconfig
            freetype
            glib
            gtk3
            icu
            krb5
            libdrm
            libgbm
            libglvnd
            libsecret
            libx11
            libxcb
            libxcomposite
            libxdamage
            libxext
            libxfixes
            libxkbcommon
            libxrandr
            nspr
            nss
            openssl
            pango
            stdenv.cc.cc.lib
            systemd
            zlib
          ];

        profile = ''
          export DOTNET_ROOT=${pkgs.dotnet-runtime_10}/share/dotnet
        '';

        runScript = "${unwrapped}/lib/azure-storage-explorer/StorageExplorer";

        extraInstallCommands = ''
          mkdir -p $out/share/applications $out/share/icons/hicolor/512x512/apps
          ln -s ${desktopItem}/share/applications/azure-storage-explorer.desktop \
            $out/share/applications/azure-storage-explorer.desktop
          ln -s ${unwrapped}/lib/azure-storage-explorer/resources/app/out/app/icon.png \
            $out/share/icons/hicolor/512x512/apps/azure-storage-explorer.png
        '';

        meta = {
          description = "GUI for managing Azure Storage resources";
          homepage = "https://azure.microsoft.com/products/storage/storage-explorer/";
          license = pkgs.lib.licenses.unfree;
          mainProgram = "azure-storage-explorer";
          platforms = [ "x86_64-linux" ];
        };
      };
    };
}
