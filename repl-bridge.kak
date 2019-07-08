# repl bridge for executing things interactively

declare-option -hidden str repl_bridge_folder "/tmp/kakoune_repl_bridge/%val{session}"
declare-option -hidden str repl_bridge_source %sh{echo "${kak_source%/*}"}
declare-option -hidden str-list repl_bridge_output

define-command -docstring 'repl-bridge-start <language>: Create FIFOs and start repl' \
    -params 1 \
    repl-bridge-start %{
    nop %sh{
        lang=$1
        folder=$kak_opt_repl_bridge_folder/$lang
        if [ ! -d $folder ]; then
            mkdir -p $folder
            mkfifo $folder/in
            mkfifo $folder/out
            ( python $kak_opt_repl_bridge_source/repl-bridge.py \
            $folder/in          \
            $folder/out         \
            $kak_opt_repl_bridge_source/config/$lang
            ) >/dev/null 2>&1 </dev/null &
        fi
    }
}

define-command -docstring 'repl-bridge-stop <language>: Stop repl and remove FIFOs' \
    -params 1 \
    repl-bridge-stop %{
    nop %sh{
        lang=$1
        folder=$kak_opt_repl_bridge_folder/$lang
        if [ -d $folder ]; then
            echo "!quit" > $folder/in
            rm $folder/in
            rm $folder/out
            rmdir -p $folder
        fi
    }
}

define-command -docstring 'repl-bridge-send <language> [command]: Evaluate selections or argument using repl-bridge return result in " register' \
repl-bridge-send -params 1..2 %{
    repl-bridge-start %arg{1}
    set-option global repl_bridge_output
    evaluate-commands %sh{
        lang=$1
        shift
        folder=$kak_opt_repl_bridge_folder/$lang

        if [ $# -eq 0 ]; then
            eval set -- "$kak_quoted_selections"
        fi
        out=""
        while [ $# -gt 0 ]; do
            output=$(cat $folder/out) && echo "set-option -add global repl_bridge_output %{$output}" &
            echo "$1" > $folder/in &
            wait
            shift
        done
    }
    set-register dquote %opt{repl_bridge_output}
}

define-command repl-bridge -params 2..3 \
    -docstring "repl-bridge <language> <repl-bridge-command> [command]" \
    -shell-script-candidates %{
    for cmd in start stop send;
        do echo $cmd;
    done
} %{ evaluate-commands %sh{
    if [ $# -eq 3 ]; then
        echo "repl-bridge-$2 $1 $3"
    else
        echo "repl-bridge-$2 $1"
    fi
}}

hook global KakEnd .* %{
    evaluate-commands %sh{
        for d in $kak_opt_repl_bridge_folder/*; do
            echo "repl-bridge-stop ${d##*/}"
        done
    }
}
