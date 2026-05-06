{ nixpkgs, lg, ... }: system: let
    pkgs = import nixpkgs { inherit system; };
    lg_pkg = lg.packages.${system}.default;
in pkgs.resholve.writeScriptBin "getpin-ui"
{
    interpreter = "${pkgs.bash}/bin/bash";

    execer = [
        "cannot:${lg_pkg}/bin/lg"
    ];

    keep.source = [ "$show_sh" "$hide_sh" ];

    inputs = [
        lg_pkg
        pkgs.coreutils
        # (pkg_import ../../scripts/color-helper.sh)
        pkgs.ncurses # for `clear` cmd
        pkgs.gnugrep
        pkgs.gawk
    ];
} (builtins.readFile ./getpin-ui.sh)
