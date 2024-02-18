{
  sources ? import ./npins,
  system ? builtins.currentSystem,
}:
let
  templet = pkgs.callPackage ./templet.nix { };
  shell = pkgs.mkShell {
    packages = with pkgs; [
      templet.cli
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
  inherit (templet) cli default;
}
