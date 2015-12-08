#
# name:             .bashrc
# author:           Harold Bradley III
# email:            harold@bradleystudio.net
# created:          Wed 02 Jan 2013 11:53:35 AM EST
#
# description:      This file is sourced during an interactive terminal
#                   session.
#

# Exit if this is a non-interactive terminal
if ! [[ $- =~ "i" ]] ; then return; fi

# Check if terminal supports colors, if so, source colors
[[ $(tput colors) -ge 8 ]] && [[ -z $_COLORS_DEFINED ]] && source $HOME/.bash_lib/colors

## SECTION: Bash Settings {{{1
set -o vi
shopt -s cdspell # Correct directory typos (cd)
# }}}

## SECTION: Bash Aliases {{{1
alias catw='cat /var/lib/portage/world'
alias cd..='cd ..'
alias cdenv='cd ~/.envi'
alias cls='clear'
alias df='df -h'
alias edbash='vim --remote-silent -o2 ~/.bashrc ~/.bash_profile'
alias edgrub='vim /boot/grub/grub.conf'
alias eixt='exit'
alias google-chrome='google-chrome &'
alias g='git'
alias gitac='git add --all && git commit'
alias gitall='git add --all'
alias gitlog='git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'
alias gimp='gimp &'
alias grep='grep --colour=auto'
alias gvim='gvim &'
alias inchroot='env-update && source /etc/profile && export PS1="(chroot) $PS1"'
alias ls='ls -A --color --group-directories-first'
alias lsg='ls -A --color --group-directories-first -g -h'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias reapache='/etc/init.d/apache2 restart'
alias rebash='source ~/.bash_profile'
alias rm='rm -i'
alias rsync='rsync -vv'
alias ssagent='eval `ssh-agent` && ssh-add ~/.ssh/id_rsa'
# }}}

## SECTION: Bash Prompts {{{1

# git_prompt() {{{2
function git_prompt() {
    if [[ $(git status 2>/dev/null) != "" ]] ; then
        _branch="$(git symbolic-ref HEAD 2>/dev/null)" || _branch="(unnamed branch)"
        _branch=${_branch:11} # Clean up "/refs/heads/"
        if [[ $(git status -s 2>/dev/null) != "" ]] ; then
            # changes uncommitted in repository
            _mod="+"
        fi
        echo "[git:"$_branch$_mod"]"
    fi
}
# }}}

# TODO: Modify for if colors script doesn't exist
#   Prompt must have double quotes for variable expansion, but single quotes to
#   prevent expansion for commands until expansion in realtime on the prompt.
if [[ ${EUID} == 0 ]] ; then # must be root:
    if [ -n "$SSH_CLIENT" ] && [ -n "$SSH_CONNECTION" ] ; then # root using ssh:
        PS1="\[${_red}\][ssh] \H\[${_blue}\]"' $( pwd ) $( git_prompt )'"\n\[${_blue}\] #\[${_colorreset}\] "
    else # root local
        PS1="\[${_red}\]\h\[${_blue}\]"' $( pwd ) $( git_prompt )'"\n\[${_blue}\] #\[${_colorreset}\] "
    fi
else
    if [ -n "$SSH_CLIENT" ] && [ -n "$SSH_CONNECTION" ] ; then # user using ssh
        PS1="\[${_green}\]ssh://\u@\H\[${_blue}\]"' $( pwd ) $( git_prompt )'"\n\[${_blue}\] \$\[${_colorreset}\] "
    else # user local
        PS1="\[${_green}\]\u\[${_blue}\]"' $( pwd ) $( git_prompt ) '"\n\[${_blue}\] \$\[${_colorreset}\] "
    fi
fi

    # PS2 is the secondary prompt when entering a multiple line command
PS2="\[${_blue}\] -> \[${_colorreset}\]"
    # PS3 is displayed when using select in bash script
PS3=" ->> "
    # PS4 is used before debug lines (when using /bin/bash -x)
PS4='+ ${FUNCNAME[0]:+${FUNCNAME[0]}():} line ${LINENO}: '
    # PROMPT_COMMAND is executed before displaying $PS1
shopt -s histappend
PROMPT_COMMAND='history -a ~/.bash_history'
HISTIGNORE='clear:ls:ls *:mutt:[bf]g:exit'
# }}}

# path() {{{1
#   prints the order of the path in human readable format
function path(){
    old=$IFS
    IFS=:
    printf "%s\n" $PATH
    IFS=$old
}
# }}}

## webmux: web dev tmux setup
# webmux() {{{1
function webmux() {
    tmux has-session -t webmux 2>/dev/null

    if [ $? != 0 ]
    then

        tmux new-session -s webmux -d

        tmux set -g base-index 1
        tmux setw -g pane-base-index 1

        tmux split-window -v -l 5 -t webmux
        tmux select-pane -t webmux:1.1

        tmux send-keys -t webmux:1.2 'clear && compass watch' C-m
    fi

    tmux attach -t webmux
}
# }}}

## emux: tmux setup for emerge
# emux() {{{1
function emux() {
    tmux has-session -t emux 2>/dev/null

    if [ $? != 0 ]
    then

        tmux new-session -s emerge -d

        tmux set -g base-index 1
        tmux setw -g pane-base-index 1

        tmux split-window -v -l 5 -t emerge
        tmux select-pane -t emerge:1.1
        tmux split-window -v -l 3 -t emerge
        tmux select-pane -t emerge:1.1
        tmux split-window -h -p 50 -t emerge
        tmux select-pane -t emerge:1.1

        tmux send-keys -t emerge:1.1 'cd ~ && clear' C-m
        tmux send-keys -t emerge:1.2 'cd /etc/portage && clear' C-m
        tmux send-keys -t emerge:1.2 'vim -p make.conf package.use package.accept_keywords package.license' C-m
        tmux send-keys -t emerge:1.3 'clear && tail -f /var/log/emerge-fetch.log' C-m
        tmux send-keys -t emerge:1.4 'clear && tail -f /var/log/emerge.log' C-m

    fi

    tmux attach -t emerge
}
# }}}

## Search Program
# s() {{{1
function s() {
    if [[ "$1" == "" ]]; then
        echo 's is a search program.'
        echo ''
        echo 'uses:'
        echo '    grep -rnI "string" /the/path'
        echo ''
        echo 'usage:'
        echo '    s 'string' /the/path'
        echo ''
        return
    fi

    if [[ -n "$2" ]]; then
        DIR=$2
    else
        DIR='./*'
    fi

    grep -rnI $1 $DIR
}
# }}}

## Copy Wrapper
# cp() {{{1
function cp() {
    if [[ "$1" == "" ]] || [[ "$2" == "" ]]; then
        echo '[!] cp requires 2 arguments.'
        return
    fi

    if [[ -d $1 ]]; then # Is first arg a directory?
        path=$2
    elif [[ -f $1 ]]; then  # First arg is a file
        possible_path=`expr match "$2" '\(.*\)\/[^/]*'`
        possible_file=`expr match "$2" '.*\/\(.*\)'`
        if [[ $possible_file == "" ]]; then
            path=$possible_path
        else
            echo -n "[?] Copy to file '$2'? Answering no will treat it as a directory. (Y/N) "
            while read -r -n 1 -s _ANSWER; do
                if [[ $_ANSWER = [Yy] ]]; then
                    path=$possible_path
                    break
                elif [[ $_ANSWER = [Nn] ]]; then
                    path=$2
                    break
                fi
            done
        fi
    else # First arg is invalid
        echo "[!] '$1' does not exist."
    fi

    if [[ ! -d "$path" ]]; then
        mkdir -p $path
    fi

    /bin/cp -vri $1 $2
}
# }}}

## Extract Program
# extract() {{{1
function extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xvjf $1     ;;
            *.tar.gz)    tar xvzf $1     ;;
            *.bz2)       bunzip2 $1      ;;
            *.rar)       unrar x $1      ;;
            *.gz)        gunzip $1       ;;
            *.tar)       tar xvf $1      ;;
            *.tbz2)      tar xvjf $1     ;;
            *.tgz)       tar xvzf $1     ;;
            *.zip)       unzip $1        ;;
            *.Z)         uncompress $1   ;;
            *.7z)        7z x $1         ;;
            *)           echo "'$1' cannot be extracted via extract" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
# }}}

#TODO: Fix this:
#if [ -e /usr/share/terminfo/x/rxvt-unicode ]; then
    export TERM='rxvt-unicode-256color'
#fi

# vim:set ft=sh sw=4 fdm=marker: