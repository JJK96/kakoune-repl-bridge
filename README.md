This bridge runs a repl shell (interpreter) for a given programming language (python and haskell have configs currently) in the background and can send selections through the shell.
This way you can do calculations while keeping memory of previous variables, so this enables you to use variables in later calculations.

This is the generalized version of https://github.com/JJK96/kakoune-python-bridge

# Dependencies

It depends on the repl shell for the programming languages of choice.  
In addition it uses the python libraries defined in [requirements.txt](./requirements.txt).  

# Install

Via [plug.kak](https://github.com/andreyorst/plug.kak):

```
plug 'JJK96/kakoune-repl-bridge' %{
  # Suggested mapping
  map global normal = ': repl-bridge python send<ret>R'
  # run some python code initially
  repl-bridge python send %{
from math import *
  }
  
}
```

Or manually:

Clone this repository to your autoload dir: `~/.config/kak/autoload/`.

# supported languages

See files in the [config](/config) directory for a list of supported languages.

New languages can easily be added, see [configuration](#configuration)

# usage

1. Select a piece of text that can be interpreted by the repl of a chosen language, then run `repl-bridge <language> send`.

or

2. run `:repl-bridge <language> send expr` where `expr` can be any python code.

This will automatically start the repl if it is not running.
Then it will execute the code using the repl and return the output in the `"` register.
This can then be used with <kbd>R</kbd> or <kbd>p</kbd> or some other command that uses the register.

The repl will first try to run the code interactively line by line, if that fails, the whole code will be executed at once.

The running repls will be shut down when the kakoune server is closed.

## Examples

python:
- Type the text `[i for i in range(10)]`
- Select the text (<kbd>x</kbd>)
- `:repl-bridge python send`
- Replace the selection (<kbd>R</kbd>)

haskell:
- Type the text `[0..10]`
- Select the text (<kbd>x</kbd>)
- `:repl-bridge haskell send`
- Replace the selection (<kbd>R</kbd>)

# configuration

Config files for languages are stored in the [config](/config) directory.

A new language can be added by creating a new file with as name the language.

The contents of the file are as follows:

```
repl cmd
prompt 
continuation prompt
additional commands
```

See the existing files for examples.

In [config/haskell](/config/haskell) the continuation prompt is set using the additional commands, so that is also a possibility.

# commands

`repl-bridge <language> <cmd>` Run `repl-bridge-cmd <language>`  
`repl-bridge-start <language>` Start the repl bridge  
`repl-bridge-stop <language>` Stop the repl bridge  
`repl-bridge-send <language>` Send the current selections through the repl bridge  
