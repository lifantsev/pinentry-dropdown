{ nixpkgs, lg, ...}: system: let
    pkgs = import nixpkgs { inherit system; };
    lga = lg.packages.${system}.lga;
    lge = lg.packages.${system}.lge;

    build = name: { inputs, execer?[], keep?{} }: pkgs.resholve.writeScriptBin name {
        interpreter = "${pkgs.bash}/bin/bash";

        inherit keep;

        execer = execer ++ [
            "cannot:${lga}/bin/lga"
            "cannot:${lge}/bin/lge"
        ];

        inputs = inputs ++ [
            lga lge
            pkgs.coreutils
        ];
    } (builtins.readFile (./. + "/${name}.sh"));

    getpin-ui = build "getpin-ui" {
        inputs = [
            pkgs.ncurses # for `clear` cmd
            pkgs.gnugrep
            pkgs.gawk
        ];
    };

    getpin = build "getpin" {
        execer = [
            "cannot:${getpin-ui}/bin/getpin-ui"
        ];

        keep.source = [ "$show_sh" "$hide_sh" ];

        inputs = [ getpin-ui ];
    };

    pinentry-dropdown = build "pinentry-dropdown" {
        execer = [
            "cannot:${getpin-ui}/bin/getpin-ui"
            "cannot:${getpin}/bin/getpin"
        ];

        inputs = [
            pkgs.gnused
            pkgs.psmisc
            getpin
            getpin-ui
        ];
    };
in {
    inherit getpin getpin-ui pinentry-dropdown;
    default = pinentry-dropdown;
}
