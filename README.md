# pinentry-dropdown

A simple pinentry program that uses a dropdown terminal as its ui. If possible, it prefers showing the ui inside an active terminal, otherwise it uses the dropdown ui.

It can work with any dropdown program, but as a result the user must themselves set up scripts that will show & hide the ui. This is made easier through a home manager module that can set the scripts up for you (currently this is only set up for [niridrop](https://github.com/lifantsev/niridrop), if you would like more open an issue or email me).

TODO add a video

## Installation

This program has three components:
- pinentry-dropdown: the pinentry server gpg can interface with
- getpin: a utility that shows a ui to get the user's pin
- getpin-ui: the ui of said utility (should be running in a dropdown terminal)

### flake
``` nix
# add the flake input
# flake.nix
inputs.pinentry-dropdown.url = "github:lifantsev/pinentry-dropdown";

# install the 3 packages
# configuration.nix
imports = [ inputs.pinentry-dropdown.nixosModules.default ];
```

### other
If you don't use nix, you may download the [scripts](https://github.com/lifantsev/pinentry-dropdown/tree/main/src), add shebangs, and install them however you usually do. The scripts optionally depend on [lg](https://github.com/lifantsev/lg), if you don't have it installed, just remove the lines that refer to `lg` with `sed -i '/ *lg / d' <script.sh>`.

## Configuration

In your dropdown program of choice, add a terminal running `getpin-ui` as a dropdown window. In `$XDG_CONFIG_HOME/getpin`, add `show.sh` and `hide.sh` that will show and hide that ui window.

This flake exposes a home-manager module that makes this easier:
``` nix
# home.nix
imports = [ inputs.pinentry-dropdown.homeManagerModules.default ];
programs.pinentry-dropdown = {
    enable = true;

    show = "pypr show getpin-ui"; # insert your scripts here
    hide = "pypr hide getpin-ui";

    # OR, instead of the show/hide above
    showhide = "niridrop"; # sets up show/hide for niridrop

    # if you use the niridrop home module
    integrations.niridrop = true; # registers getpin-ui as a dropdown window in niridrop
};
```

## Usage

To use this script as your default pinentry:
``` nix
# home.nix
services.gpg-agent.pinentry.package = pkgs.pinentry-dropdown;
```

### getpin
All arguments are optional. Communicates with `getpin-ui` over ipc and prints the collected pin.
``` sh
# example
getpin --title "enter password to unlock secrets" --prompt "pass"
getpin --title "enter password to unlock secrets" --error "wrong pass (attempt 2/3)"
```
--title: string at the top of the ui in _blue color_.

--prompt: string at the start of input line in _green color_

--error: prompt but using _red color_ (if both --prompt & --error are set, error takes precedence)

--desc: string between title & prompt in _gray color_

--fifo: stem of fifo file to use to communicate to `getpin-ui` (use with getpin-ui --fifo -- this is used by pinentry-niridrop when creating a getpin-ui in an active tty instead of using the dropdown ui)

--donthide: don't hide the ui after collecting a pin

--justhide: just hide the ui and exit (don't collect pin)

--showpin: show the pin as the user types it (instead of obfuscating with '*' chars)

### getpin-ui
All arguments are optional. Awaits ipc communication from `getpin`.
``` sh
getpin --fifo "test" --once
```
--fifo: set the stem of the fifo file to use for ipc (use with getpin --fifo)

--getfifo: print the path to the ipc fifo and exit

--justhide: just hide the ui and exit

--once: only serve one getpin request before exiting (by default it always awaits further requests)

TODO demo video
