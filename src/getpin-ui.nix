{ nixpkgs, lg, niridrop, ... }: system: let
    pkgs = import nixpkgs { inherit system; };
    lg_pkg = lg.packages.${system}.default;
    niridrop_pkg = niridrop.packages.${system}.default;
in pkgs.resholve.writeScriptBin "getpin-ui"
{
    interpreter = "${pkgs.bash}/bin/bash";

    execer = [
        "cannot:${niridrop_pkg}/bin/niridrop"
        "cannot:${lg_pkg}/bin/lg"
    ];

    inputs = [
        niridrop_pkg
        lg_pkg
        pkgs.coreutils
        # (pkg_import ../../scripts/color-helper.sh)
        pkgs.ncurses # for `clear` cmd
        pkgs.gnugrep
        pkgs.gawk
    ];
} (builtins.readFile ./getpin-ui.sh)
