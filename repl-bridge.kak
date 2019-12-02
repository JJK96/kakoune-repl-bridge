# repl bridge for executing things interactively

declare-option -hidden str repl_bridge_folder "/tmp/kakoune_repl_bridge/%val{session}"
declare-option -hidden str repl_bridge_source %sh{echo "${kak_source%/*}"}
declare-option bool repl_bridge_fifo_enabled false

define-command -docstring 'repl-bridge-enable-fifo <language>: Open FIFO and start terminal' \
repl-bridge-enable-fifo -params 1 %{
    evaluate-commands %sh{
        lang=$1
        folder=$kak_opt_repl_bridge_folder/$lang
        mkfifo $folder/fifo
        echo "terminal tail -f $folder/fifo"
    }
    set-option global repl_bridge_fifo_enabled true
}

define-command -docstring 'repl-bridge-disable-fifo <language>: Close FIFO' \
repl-bridge-disable-fifo -params 1 %{
    nop %sh{
        lang=$1
        folder=$kak_opt_repl_bridge_folder/$lang
        rm $folder/fifo
    }
    set-option global repl_bridge_fifo_enabled false
}

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
    evaluate-commands %sh{
        lang=$1
        shift
        folder=$kak_opt_repl_bridge_folder/$lang
        cat_command="cat $folder/out"
        if $kak_opt_repl_bridge_fifo_enabled; then
            cat_command="$cat_command | tee -a $folder/fifo"
        fi

        if [ $# -eq 0 ]; then
            eval set -- "$kak_quoted_selections"
        fi
        out=""
        while [ $# -gt 0 ]; do
            output=$(eval $cat_command) && echo "set-register dquote %{$output}" &
            echo "$1" > $folder/in &
            wait
            shift
        done
    }
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
