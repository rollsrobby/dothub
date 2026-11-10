{ lib }:
let
  css = color: "#${color}";
  rgb =
    color:
    lib.concatMapStringsSep ", "
      (offset: toString (lib.fromHexString (builtins.substring offset 2 color)))
      [
        0
        2
        4
      ];
in
{
  inherit css rgb;
  gtkDefinitions =
    colors:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: color: "@define-color ${name} ${css color};") colors
    )
    + "\n";
  hyprlock = color: alpha: "rgba(${rgb color}, ${alpha})";
}
