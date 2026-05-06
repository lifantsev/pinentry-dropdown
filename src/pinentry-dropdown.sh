# article about pinentry: https://velvetcache.org/2023/03/26/a-peek-inside-pinentry/
# pinentry documentation: https://gist.github.com/mdeguzis/05d1f284f931223624834788da045c65

export LGENABLE=0 # other apps inherit this, but pinentry runs in a clean environment (so need to set manually)
export LGSTEM=pinentry

lg start

lg I "HOME[$HOME]"
lg I "XDG_STATE_HOME[$XDG_STATE_HOME]"
lg I "XDG_RUNTIME_DIR[$XDG_RUNTIME_DIR]"

function bye() {
    lg I "terminating connection: assuan bye"
    echo BYE
    exit 1
}

function assuan() {
    lg . "  responding: $1"
    echo "$1"
}

if ! command -v getpin &> /dev/null;
then lg E "getpin is not available in this environment, exiting" ; bye
fi

if ! command -v sed &> /dev/null;
then lg E "sed is not available in this environment, exiting" ; bye
fi

# NOTE --donthide and --justhide MUST BE FIRST ARGUMENT!!!!
function mygetpin() {
    lg . "mygetpin with ttyname[$ttyname] DISPLAY[$DISPLAY] ttytype[$ttytype]"

    # fallback to standard getpin if environment isn't suitable for tty control
    if [ -z "$ttyname" ];
    then getpin "$@" ; return ; fi

    if [ -n "${DISPLAY:-}" ] && [ "$ttytype" == linux ]
    then getpin "$@" ; return ; fi

    # control the tty given to use by gpg-agent to show getpin on a specific terminal
    lg . "using custom tty control"

    # process first arg
    flag_donthide=0
    flag_justhide=0
    case "${1:-}" in
        "--donthide") flag_donthide=1 ; shift ;;
        "--justhide") flag_justhide=1 ; shift ;;
    esac

    if (( ! flag_justhide )); then
        fuser --kill -STOP "$ttyname" &>/dev/null
        echo > "$ttyname"

        # shellcheck disable=SC2094
        getpin-ui --once --fifo pinentry > "$ttyname" < "$ttyname" &
        getpin --fifo pinentry "$@"
    fi

    (( flag_donthide )) && return 0

    fuser --kill -CONT "$ttyname" &>/dev/null
}

prompt="Passphrase"
desc=""
error=""
repeat=""

ttytype=""
ttyname=""

assuan "OK Pleased to meet you"

while :; do
    if ! read -r cmd args 2>/dev/null; then sleep 0.4; continue ; fi
    ok=1

    lg . "assuan got cmd[$cmd] with args[$args]"

    case "$cmd" in
        "BYE"*) assuan "OK Closing connection"; exit 0 ;;
        "GETPIN"*)
            desc_head="$(echo "$desc" | head -n 1 | sed -e 's|Please enter the passphrase to|Please|' -e 's|^\s*||' -e 's|\s*$||')"
            desc_tail="$(echo "$desc" | tail -n +2 | sed -e 's|^\s*||' -e 's|\s*$||')"
            [ -n "$desc_tail" ] && desc_tail+="\n"

            if [ -z "$repeat" ]; then
                lg I "getting pin"

                if ! pin="$(mygetpin --title "$desc_head" --desc "$desc_tail" --prompt "$prompt" --error "$error")"
                then pin=""; fi
            else
                while true; do
                    lg I "getting pin"

                    if ! pin="$(mygetpin --donthide --title "$desc_head" --desc "$desc_tail" --prompt "$prompt" --error "$error")"
                    then pin=""; fi
                    [ -z "$pin" ] && break

                    error=""

                    lg I "getting repeat pin"

                    if ! repeat_pin="$(mygetpin --donthide --title "$desc_head" --desc "$desc_tail" --prompt "$repeat" --error "$error")"
                    then repeat_pin=""; fi

                    [ -z "$repeat_pin" ] && pin="" && break # break on cancel

                    if [ "$repeat_pin" == "$pin" ]; then
                        lg I "success: pins match"
                        assuan "S PIN_REPEATED"
                        break
                    else
                        lg I "fail: pins didn't match, trying again"
                        error="Did not match"
                    fi
                done

                mygetpin --justhide &
            fi

            if [ -n "$pin" ];
            then echo "D $pin" ; lg I "responding with [[pin]] (hidden)"
            else assuan "ERR 83886179 Operation cancelled <getpin>"; ok=0
            fi

            # reset
            repeat=""
            error=""
        ;;
        "CONFIRM"*)
            if ! res="$(mygetpin --showpin --title "Please confirm: $desc" --prompt "[yes]/no")"; then
                lg E "getpin exited with an error, using res=no" > /dev/null # devnull to not screw with assuan ipc
                res="no"
            fi

            if [[ "${res,,}" == "n"* ]]; then
                assuan "ERR 83886179 Operation cancelled <getpin>"; ok=0
            fi
        ;;
        "MESSAGE"*)
            mygetpin --title "$desc" --desc "Press enter to dismiss" ||:
        ;;
        "SETDESC"*)
            # args=Please enter the passphrase... %0A %22 followed by <keyinfo>
            # shellcheck disable=SC2059
            desc="$(printf "${args//\%/\\x}")"
            ;;
        "SETPROMPT"*) prompt="${args%:}" ;; # Passphrase:
        "SETERROR"*) error="${args#Bad }" ;; # Bad Passphrase (try 2 of 3)

        "SETREPEAT"*) repeat="$args" ;;

        "GETINFO"*) case "$args" in
            "pid" ) assuan "D $$" ;;
            "version" ) assuan "D 0" ;;
            "flavor" ) assuan "D pinentry-pypr" ;;
            "ttyinfo" ) assuan "D - - - - $(id -u 2>/dev/null || echo 0)/$(id -g 2>/dev/null || echo 0) -" ;;
        esac ;;

        "OPTION"*) case "$args" in
            "ttytype="* ) ttytype="${args#ttytype=}";;
            "ttyname="* ) ttyname="${args#ttyname=}";;
        esac ;;
    esac

    (( ok )) && assuan "OK Success"
done

lg finish

