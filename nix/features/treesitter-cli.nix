{
  perSystem =
    { pkgs, ... }:
    {
      packages.tree-sitter = pkgs.rustPlatform.buildRustPackage rec {
        pname = "tree-sitter";
        version = "0.26.8";

        src = pkgs.fetchFromGitHub {
          owner = "tree-sitter";
          repo = "tree-sitter";
          rev = "v${version}";
          hash = "sha256-fcFEfoALrbpBD6rWogxJ7FNVlvDQgswoX9ylRgko+8Q=";
        };

        cargoHash = "sha256-9FeWnWWPUWmMF15Psmul8GxGv2JceHWc2WZPmOr81gw=";

        nativeBuildInputs = [
          pkgs.pkg-config
          pkgs.rustPlatform.bindgenHook
        ];

        buildInputs = [
          pkgs.openssl
        ];

        doCheck = false;
      };
    };
}
