# getpin-ui

COL_DEFAULT="\033[0m"
COL_BLUE="\033[0;34m"
COL_RED="\033[0;31m"
COL_GREEN="\033[0;32m"
COL_DARK="\033[0;37m"

export LGSTEM="getpin"
export LGSPEC="ui"

lg start

function finish() { lg finish ; exit "$1" ; }

function starread() {
    # read char by char & print stars as we go

    while IFS= read -r -s -n 1 char; do
        if [[ -z "$char" ]]; then echo ; break ; fi # handle <CR>

        if [[ "$char" == $'\x08' || "$char" == $'\x7f' ]]; then # handle <BS>
            if [[ -n "$pin" ]]; then
                pin="${pin%?}"
                echo -en "\b \b" # back, print space, back
            fi
        else
            pin+="$char"
            printf "*"
        fi
    done
}

flag_getfifo=0
flag_once=0
flag_fifo=0
fifo_name=default

while [ -n "${1:-}" ]; do
    case "$1" in
        "--fifo") # set fifo stem to use
            if [ -z "${2:-}" ] || [[ "$2" == "-"* ]]; then
                lg E "option --fifo expects an argument, but it was either not provided or invalid"
                finish 1
            fi

            flag_fifo=1
            lg . "set flag_fifo[$flag_fifo]"
            fifo_name="$2" ; shift
            lg . "set fifo_name[$fifo_name]"
        ;;
        "--getfifo") # just print fifo path
            flag_getfifo=1
            lg . "set flag_getfifo[$flag_getfifo]"
        ;;
        "--once") # only serve one request before exiting
            lg . "set flag_once[$flag_once]"
            flag_once=1
        ;;
        *)
            lg E "unrecognized flag[$1]"
            finish 1
        ;;
    esac

    shift
done

fifo_path="$XDG_STATE_HOME/getpin/$fifo_name.fifo"

if (( flag_getfifo )); then
    lg I "printing fifo_path[$fifo_path] and exiting..."
    echo "$fifo_path"
    finish 0
fi

if [ -e "$fifo_path" ]; then # we ignore the chance there is a directory here
    lg I "removing existing fifo: $fifo_path"
    rm "$fifo_path" &> /dev/null || :
fi

lg I "initializing fifo: $fifo_path"
mkdir -p "$(dirname "$fifo_path")"
mkfifo "$fifo_path"

show_sh="$XDG_CONFIG_HOME/getpin/show.sh"
hide_sh="$XDG_CONFIG_HOME/getpin/hide.sh"

if [ ! -f "$show_sh" ]; then lg E "expecting a script to show the ui dropdown at [$show_sh]" ; exit 1 ; fi
if [ ! -f "$hide_sh" ]; then lg E "expecting a script to hide the ui dropdown at [$hide_sh]" ; exit 1 ; fi

while true; do
    lg F "awaiting input from fifo: $fifo_path"
    clear

    input="$(cat "$fifo_path")"
    lg . "got input from infile"

    showpin="$(echo "$input" | awk -v RS='\x1F' 'NR==1')"
    donthide="$(echo "$input"| awk -v RS='\x1F' 'NR==2')"
    title="$(echo "$input"   | awk -v RS='\x1F' 'NR==3')"
    desc="$(echo "$input"    | awk -v RS='\x1F' 'NR==4')"
    prompt="$(echo "$input"  | awk -v RS='\x1F' 'NR==5')"
    error="$(echo "$input"   | awk -v RS='\x1F' 'NR==6')"

    if (( ! flag_fifo )); then # let user handle showing ui if they are using custom fifo
        lg . "opening ui"
        . "$show_sh"
    fi

    [ -n "$title" ] && printf "$COL_BLUE$title$COL_DEFAULT\n"
    [ -n "$desc" ] && printf "$COL_DARK$desc$COL_DEFAULT\n"

    if [ -n "$error" ]
    then printf "$COL_RED$error: $COL_DEFAULT"
    else
        [ -n "$prompt" ] && printf "$COL_GREEN$prompt: $COL_DEFAULT"
    fi

    pin=""
    if (( showpin ));
    then read -r pin
    else starread
    fi

    lg F "returning [[pin]] to fifo"

    echo "$pin" > "$fifo_path"

    if (( ! flag_fifo )) && (( ! donthide )); then
        lg . "hiding ui"
        . "$hide_sh"
    fi

    if (( flag_once )); then
        lg I "we got --once, finishing up"
        lg . "removing fifo[$fifo_path]"
        rm "$fifo_path" &> /dev/null || :

        lg . "exiting..."
        finish 0
    fi
done

