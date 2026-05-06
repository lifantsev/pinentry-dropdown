{ lib, config, ... }: {
    options.programs.pinentry-niridrop.enable = lib.mkEnableOption "usage of the niridrop module to register the getpin-ui dropdown";

    config = lib.mkIf config.programs.pinentry-niridrop.enable {
        programs.niri.niridrop.windows.getpin-ui = {
            app_id = "getpin-ui";
            cmd = "${config.home.sessionVariables.TERMINAL} --class getpin-ui getpin-ui";
            lazy = false;
            size = [ 0.3 0.16 ];
        };
    };
}

