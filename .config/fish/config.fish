if status --is-login; and test (tty) = "/dev/tty1"
    exec dbus-run-session sway
end

set -g __fish_git_prompt_showdirtystate      'yes'
set -g __fish_git_prompt_showuntrackedfiles  'yes'
set -g __fish_git_prompt_char_stateseparator ' '
set -g __fish_git_prompt_showstashstate      ' '
set -g __fish_git_prompt_showupstream        "informative"
set -g fish_prompt_pwd_dir_length             3

# vi mode
fish_vi_key_bindings

# editor
set -gx EDITOR kak
set -gx VISUAL kak

# locale
set -gx LANG en_US.UTF-8

# gpg
set -gx GPG_TTY (tty)

# history
set -g fish_history_max 5000000

# paths
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.config/emacs/bin
fish_add_path $HOME/go/bin


if test -d $HOME/.elan/bin
    fish_add_path $HOME/.elan/bin
end

if test -d $HOME/.local/bin
    fish_add_path $HOME/.local/bin
end

# kitty integration
if type -q kitty
    alias icat "kitty +kitten icat"
    alias issh "kitty +kitten ssh"
end

alias vi vim

alias grep "grep --color=auto"
alias egrep "egrep --color=auto"
alias fgrep "fgrep --color=auto"

alias cp "cp -i"
alias mv "mv -i"
alias rm "rm -i"

if command -v eza > /dev/null
	abbr -a l 'eza'
	abbr -a ls 'eza'
	abbr -a ll 'eza -l'
	abbr -a lll 'eza -la'
else
	abbr -a l 'ls'
	abbr -a ll 'ls -l'
	abbr -a lll 'ls -la'
end

alias free "free -h"
alias df "df -h"
alias du "du -h"

alias open xdg-open

alias man batman

alias aria2 "aria2c -x 16 -s 16 -k 1M -c"

abbr -a G --position anywhere  "| grep   "
abbr -a L --position anywhere  "| less   "
abbr -a H --position anywhere  "| head   "
abbr -a T --position anywhere  "| tail   "
abbr -a WC--position anywhere  "| wc -l  "
abbr -a S --position anywhere  "| sort   "
abbr -a U --position anywhere  "| sort -u"
abbr -a W --position anywhere  "| wl-copy"
abbr -a P --position anywhere  "| fzf    "
abbr -a F --position anywhere  "| canon | f0x"
abbr -a J --position anywhere  "| jq"
abbr -a N --position anywhere  "2>/dev/null"

# opam
if test -r "$HOME/.opam/opam-init/init.fish"
    source "$HOME/.opam/opam-init/init.fish" > /dev/null ^/dev/null
end
