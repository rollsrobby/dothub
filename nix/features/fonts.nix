{
  flake.nixosModules.fonts =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        nerd-fonts.geist-mono
        nerd-fonts.monaspace
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        roboto
        liberation_ttf
        dejavu_fonts
        corefonts
      ];

      fonts.fontconfig.localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <match target="pattern">
            <test name="family" compare="eq">
              <string>Segoe UI</string>
            </test>
            <edit name="family" mode="assign" binding="strong">
              <string>Roboto</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
}
