########################
####### EXPORT #########
########################

export ZSH="$HOME/.oh-my-zsh"

export HISTORY_IGNORE="(ls|cd|pwd|exit|reboot|poweroff|history|cd -|cd ..|sudo poweroff -f|sudo reboot -f|code|code .|)"

export EDITOR="vim"              # $EDITOR use Vim in terminal
export VISUAL="vim"           # $VISUAL use Vim in GUI mode
export LANG=en_US.UTF-8

#########################
######### PATH ##########
#########################


if [ -d "$HOME/.bin" ] ;
then PATH="$HOME/.bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ;
then PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/Applications" ] ;
then PATH="$HOME/Applications:$PATH"
fi

if [ -d "$HOME/.cargo/bin" ]
then PATH="$HOME/.cargo/bin:$PATH"
fi

##################################
########## OMZ Gerneral ##########
##################################

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

## omz plugins
plugins=(git
  mercurial
  zsh-syntax-highlighting
  zsh-history-substring-search
  emoji
  yarn
  man
  fasd
  emacs
  poetry
gpg-agent httpie git-flow)

source $ZSH/oh-my-zsh.sh

#########################
###### SET VI MODE ######
#########################

# Comment this line out to enable default emacs-like bindings
bindkey -v

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

##########################
####### functions ########
##########################

SAVEIFS=$IFS
IFS=$(echo -en "
")

function extract {
  if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
  else
    for n in "$@"
    do
      if [ -f "$n" ] ; then
        case "${n%,}" in
          *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
          tar xvf "$n"       ;;
          *.lzma)      unlzma ./"$n"      ;;
          *.bz2)       bunzip2 ./"$n"     ;;
          *.cbr|*.rar)       unrar x -ad ./"$n" ;;
          *.gz)        gunzip ./"$n"      ;;
          *.cbz|*.epub|*.zip)       unzip ./"$n"       ;;
          *.z)         uncompress ./"$n"  ;;
          *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
          7z x ./"$n"        ;;
          *.xz)        unxz ./"$n"        ;;
          *.exe)       cabextract ./"$n"  ;;
          *.cpio)      cpio -id < ./"$n"  ;;
          *.cba|*.ace)      unace x ./"$n"      ;;
          *)
            echo "extract: '$n' - unknown archive method"
            return 1
          ;;
        esac
      else
        echo "'$n' - file does not exist"
        return 1
      fi
    done
  fi
}

# navigation
up () {
  local d=""
  local limit="$1"
  
  # Default to limit of 1
  if [ -z "$limit" ] || [ "$limit" -le 0 ]; then
    limit=1
  fi
  
  for ((i=1;i<=limit;i++)); do
    d="../$d"
  done
  
  # perform cd. Show error if cd fails
  if ! cd "$d"; then
    echo "Couldn't go up $limit dirs.";
  fi
}


###############
### ALIASES ###
###############

## root privileges
alias doas="doas --"

## vim and emacs
alias vi=vim
alias em="/usr/bin/emacs -nw"
alias emacs="emacsclient -c -a 'emacs'"

## doomemacs
alias doomsync="~/.emacs.d/bin/doom sync"
alias doomdoctor="~/.emacs.d/bin/doom doctor"
alias doomupgrade="~/.emacs.d/bin/doom upgrade"
alias doompurge="~/.emacs.d/bin/doom purge"

## add color to grep(s)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

## confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

## human-readable sizes
alias free='free -h'
alias df='df -h'

alias open='xdg-open'

# kitty

if [ -f `which kitty` ]; then
  
  ## show img in terminal
  alias icat="kitty +kitten icat"
  
  ## connect via ssh
  alias issh="kitty +kitten ssh"
fi

# youtube-dl

alias yta-aac="youtube-dl --extract-audio --audio-format aac "
alias yta-best="youtube-dl --extract-audio --audio-format best "
alias yta-flac="youtube-dl --extract-audio --audio-format flac "
alias yta-m4a="youtube-dl --extract-audio --audio-format m4a "
alias yta-mp3="youtube-dl --extract-audio --audio-format mp3 "
alias yta-opus="youtube-dl --extract-audio --audio-format opus "
alias yta-vorbis="youtube-dl --extract-audio --audio-format vorbis "
alias yta-wav="youtube-dl --extract-audio --audio-format wav "
alias ytv-best="youtube-dl -f bestvideo+bestaudio "

# switch between shells

alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Now log out.'"
## BASH INSULTER (works in zsh though)
if [ -f /etc/bash.command-not-found ]; then
  . /etc/bash.command-not-found
fi

## use fzf plugin
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

