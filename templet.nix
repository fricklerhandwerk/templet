{ pkgs, npins, nix }:
let
  lib = pkgs.lib;
in
rec {
  cli = pkgs.writeShellApplication {
    name = "templet";
    # `nix` is not in there deliberately.
    # it wouldn't be safe to run a build if the Nix from Nixpkgs is newer than
    # the one in the user's environment, as that may change the local store
    # database schema, which will produce obscure errors when accessed with the
    # older Nix again.
    runtimeInputs = [ npins ];
    text = ''
      packages=()

      print_usage() {
        echo "Usage:"
        echo "templet shell -p [package name]... [-- [npins arguments]]"
        echo
        echo "-p / --packages : List of Nixpkgs derivations"
        echo "--              : All following arguments are passed to"
        echo "                  'npins add github nixos nixpkgs'"
      }

      while [[ $# -gt 0 ]]; do
        case $1 in
          shell)
            shift
            while [[ $# -gt 0 ]]; do
              case $1 in
                -p|--packages)
                  shift
                  while [[ $# -gt 0 && $1 =~ ^[a-z] ]]; do
                    packages+=("$1")
                    shift
                  done
                  ;;
                --)
                  shift
                  break
                  ;;
                *)
                  echo "Unknown argument '$1'"
                  echo
                  print_usage
                  exit 1
                  ;;
              esac
            done
            break
            ;;
          *)
            echo "Unknown sub-command '$1'"
            echo
            print_usage
            exit 1
            ;;
        esac
        print_usage
        exit 1
      done

      result=$(nix-build ${./.} -A default --no-out-link --argstr packages "''${packages[*]}")
      cp "$result" default.nix
      cp ${./shell.nix} shell.nix
      npins init --bare
      echo "$@"
      npins add github nixos nixpkgs "$@"
    '';
  };
  default = { packages }: pkgs.writeText "default.nix" ''
    {
      sources ? import ./npins,
      system ? builtins.currentSystem,
    }:
    let
      shell = pkgs.mkShell {
        packages = with pkgs; [
          ${
            # yes, this is a hack
            lib.concatStringsSep "\n      "
            (lib.strings.splitString " " packages)
          }
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
  '';
}
