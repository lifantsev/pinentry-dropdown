{ self, nixpkgs, lg, ... }: system: let
    pkgs = import nixpkgs { inherit system; };
    lg_pkg = lg.packages.${system}.default;
    getpin-ui_pkg = self.packages.${system}.getpin-ui;
in pkgs.resholve.writeScriptBin "getpin"
{
    interpreter = "${pkgs.bash}/bin/bash";

    execer = [
        "cannot:${getpin-ui_pkg}/bin/getpin-ui"
        "cannot:${lg_pkg}/bin/lg"
    ];

    keep.source = [ "$show_sh" "$hide_sh" ];

    inputs = [
        pkgs.coreutils
        lg_pkg
        getpin-ui_pkg
    ];
} (builtins.readFile ./getpin.sh)
