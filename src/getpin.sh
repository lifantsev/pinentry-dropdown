# getpin

export LGSTEM="getpin"
export LGSPEC="cli"

lg start

function finish() { lg finish ; exit "$1" ; }

flag_fifo=0
fifo_name=""
flag_title=""
flag_desc=""
flag_prompt=""
flag_error=""
flag_showpin=0
flag_donthide=0
flag_justhide=0

while [ $# -gt 0 ]; do
    flag="$1"
    shift

    lg I "handling flag[$flag]"

    case "$flag" in
        "--fifo"|"--title"|"--desc"|"--prompt"|"--error")
            if [ $# -eq 0 ] || [[ "${1:-}" == "-"* ]]; then
                lg E "option $flag expects an argument[${1:-}], but it was malformed, exiting";
                finish 1;
            fi
            
            arg="$1"
            shift

            lg . "found arg[$arg]"
        ;;
    esac

    case "$flag" in
        "--fifo") # set fifo stem to use
            flag_fifo=1
            lg . "set flag_fifo[$flag_fifo]"
            fifo_name="$arg"
            lg . "set fifo_name[$fifo_name]"
        ;;

        "--title")   flag_title="$arg" ; lg . "set flag_title[$flag_title]" ;;
        "--desc")     flag_desc="$arg" ; lg . "set flag_desc[$flag_desc]" ;;
        "--prompt") flag_prompt="$arg" ; lg . "set flag_prompt[$flag_prompt]" ;;
        "--error")   flag_error="$arg" ; lg . "set fifo_name[$flag_error]" ;;

        "--showpin") flag_showpin=1    ; lg . "set flag_showpin[$flag_showpin]" ;;
        "--donthide") flag_donthide=1  ; lg . "set flag_donthide[$flag_donthide]" ;;
        "--justhide") flag_justhide=1  ; lg . "set flag_justhide[$flag_justhide]" ;;

        *) lg E "unrecognized flag[$flag]" ; finish 1 ;;
    esac
done

if (( flag_fifo ));
then fifo_path="$(getpin-ui --fifo "$fifo_name" --getfifo)"
else fifo_path="$(getpin-ui --getfifo)"
fi

show_sh="$XDG_CONFIG_HOME/getpin/show.sh"
hide_sh="$XDG_CONFIG_HOME/getpin/hide.sh"

if [ ! -f "$show_sh" ]; then lg E "expecting a script to show the ui dropdown at [$show_sh]" ; exit 1 ; fi
if [ ! -f "$hide_sh" ]; then lg E "expecting a script to hide the ui dropdown at [$hide_sh]" ; exit 1 ; fi

if (( flag_justhide )); then
    . "$hide_sh"
    exit 0
fi

lg I "writing request to fifo[$fifo_path]"

printf "%s\x1F%s\x1F%s\x1F%s\x1F%s\x1F%s\x1F" "$flag_showpin" "$flag_donthide" "$flag_title" "$flag_desc" "$flag_prompt" "$flag_error" > "$fifo_path"

lg . "awaiting result from fifo[$fifo_path]"
pin="$(cat "$fifo_path")"
lg . "got a pin, printing it"
echo "$pin"

