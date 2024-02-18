{ lib, findutils, gnused, npins, nix, writeShellApplication }:
rec {
  cli = writeShellApplication {
    name = "templet";
    runtimeInputs = [ npins nix findutils gnused ];
    text = ''
      packages=()

      print_usage() {
        echo "Usage:"
        echo "templet shell -p [package name]... [-- [npins arguments]]"
        echo
        echo "-p / --packages : List of Nixpkgs packages"
        echo "--              : All following arguments are passed to"
        echo "                  'npins add github nixos nixpkgs'"
        echo "                  If not specified: '--branch nixpkgs-unstable'"
      }

      while [[ $# -gt 0 ]]; do
        case $1 in
          shell)
            shift
            while [[ $# -gt 0 ]]; do
              case $1 in
                -p|--packages)
                  shift
                  while [[ $# -gt 0 && $1 =~ ^[a-zA-Z_] ]]; do
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

      tmp="$(mktemp -d)"
      pushd "$tmp"

      npins init --bare
      if [[ $# -gt 0 ]]; then
        npins add github nixos nixpkgs "$@"
      else
        npins add github nixos nixpkgs --branch nixpkgs-unstable
      fi
      result=$(nix-instantiate --eval ${./.} -A default --argstr packages "''${packages[*]}")
      # unquote
      result="''${result%\"*}"
      result="''${result#\"*}"
      printf "%b" "$result" > default.nix
      install -m 644 ${./src/shell.nix} shell.nix

      popd

      source_dir="$tmp"
      target_dir="$(pwd)"
      source_files=$(find "$source_dir" -type f | sed "s|^$source_dir/||" | sort)
      target_files=$(find "$target_dir" -type f | sed "s|^$target_dir/||" | sort)
      existing=$(comm -12 <(echo "$source_files") <(echo "$target_files"))
      if [[ -n "$existing" ]]; then
        echo "Aborting, some target files already exist:"
        echo "$existing"
        exit 1
      fi

      mv "$tmp"/* .
    '';
  };
  default = { packages }:
    with lib;
    let
      npins = [ "      npins" ];
      template = readFile ./src/default.nix;
      replacement = concatStringsSep "\n      " (npins ++ (if packages != "" then splitString " " packages else [ ]));
    in
    replaceStrings npins [ replacement ] template;
}
