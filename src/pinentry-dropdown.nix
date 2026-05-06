{ self, nixpkgs, lg, ... }: system: let
    pkgs = import nixpkgs { inherit system; };
    lg_pkg = lg.packages.${system}.default;
    getpin-ui_pkg = self.packages.${system}.getpin-ui;
    getpin_pkg = self.packages.${system}.getpin;
in pkgs.resholve.writeScriptBin "pinentry-dropdown"
{
    interpreter = "${pkgs.bash}/bin/bash";

    execer = [
        "cannot:${lg_pkg}/bin/lg"
        "cannot:${getpin_pkg}/bin/getpin"
        "cannot:${getpin-ui_pkg}/bin/getpin-ui"
    ];

    inputs = [
        pkgs.coreutils
        pkgs.gnused
        pkgs.psmisc
        lg_pkg
        getpin-ui_pkg
        getpin_pkg
    ];
} (builtins.readFile ./pinentry-dropdown.sh)
