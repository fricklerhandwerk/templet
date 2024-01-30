{
  sources ? import ./npins,
  system ? builtins.currentSystem,
}:
let
  shell = pkgs.mkShell {
    packages = with pkgs; [
      npins
    ];
  };
  pkgs = import sources.nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  };
in
{
  inherit shell;
}
