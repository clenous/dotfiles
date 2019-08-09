export TERM=xterm-256color

if [ -e "$HOME/.zshrc.local" ]; then
  . "$HOME/.zshrc.local"
fi

if [ -e "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
	. "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

gitStatus() {
  local branch_name st branch_status

  if [ ! -e  ".git" ]; then
    return
  fi
  branch_name=`git rev-parse --abbrev-ref HEAD 2> /dev/null`
  st=`git status 2> /dev/null`
  if [[ -n `echo "$st" | grep "^nothing to"` ]]; then
    branch_status="\e[38;5;2m"
  elif [[ -n `echo "$st" | grep "^Untracked files"` ]]; then
    branch_status="\e[38;5;1m?"
  elif [[ -n `echo "$st" | grep "^Changes not staged for commit"` ]]; then
    branch_status="\e[38;5;1m+"
  elif [[ -n `echo "$st" | grep "^Changes to be committed"` ]]; then
    branch_status="\e[38;5;3m!"
  elif [[ -n `echo "$st" | grep "^rebase in progress"` ]]; then
    echo "\e[38;5;1m!(no branch)"
    return
  else
    branch_status="\e[38;5;4m"
  fi
  echo "${branch_status}[$branch_name]\e[m"
}

ignore() {
  curl -f https://raw.githubusercontent.com/github/gitignore/master/$(echo $1|awk '{print toupper(substr($1,1,1))substr($1,2)}').gitignore >> .gitignore
}

precmd() {
  local RESULT=$?
  if type md5sum > /dev/null 2>&1; then
    local HOSTCOLOR=$'\e[38;05;'"$(printf "%d\n" 0x$(hostname|md5sum|md5sum|cut -c1-2))"'m'
  elif type md5 > /dev/null 2>&1; then
    local HOSTCOLOR=$'\e[38;05;'"$(printf "%d\n" 0x$(hostname|md5|md5|cut -c1-2))"'m'
  else
    local HOSTCOLOR=$'\e[0m'
  fi
  print -P "\n%n@$HOSTCOLOR$(hostname)\e[m %. $(gitStatus)"

  if [ ! -z "$SLACK_NOTIFY" ] || [ ! -z "$DISCORD_NOTIFY" ]; then
    if [ $TTYIDLE -gt 10  -a "$execflg" = true ]; then
      local title="$RESULT> $prev_command"
      if [ $RESULT -eq 0 ]; then
        local color="#00d000"
      else
        local color="#d00000"
      fi
      json=`cat << EOS
{
  "attachments": [
    {
      "color": "$color",
      "title": "$title",
      "mrkdwn_in": ["fields"],
      "fields": [
        {
          "title": "command",
          "value": "\\\`$prev_command\\\`",
          "short": false
        },
        {
          "title": "directory",
          "value": "\\\`$(pwd)\\\`",
          "short": false
        },
        {
          "title": "hostname",
          "value": "$(hostname)",
          "short": true
        },
        {
          "title": "user",
          "value": "$(whoami)",
          "short": true
        },
        {
          "title": "elapsed time",
          "value": "$TTYIDLE seconds",
          "short": true
        }
      ]
    }
  ]
}
EOS
`
      if [ ! -z "$SLACK_NOTIFY" ]; then
        curl -H 'Content-Type:application/json' -d $json $SLACK_NOTIFY
      fi
      if [ ! -z "$DISCORD_NOTIFY" ]; then
        curl -H 'Content-Type:application/json' -d $json "$DISCORD_NOTIFY/slack"
      fi
    fi
  fi
  execflg=false
}

preexec() {
  prev_executed_at=`date +%F\ %T`
  prev_command=$2
  execflg=true
}

peco-history-selection() {
  case ${OSTYPE} in
    darwin*)
      BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
      ;;
    linux*)
      BUFFER=`history -n 1 | tac  | awk '!a[$0]++' | peco`
      ;;
  esac
  CURSOR=$#BUFFER
  zle reset-prompt
}

if type peco > /dev/null 2>&1; then
  zle -N peco-history-selection
  bindkey '^R' peco-history-selection
fi

export PROMPT="> %F{green}$%f "
export PROMPT2="> "
export HISTFILE="${HOME}/.zsh_history"
export HISTSIZE="1000"
export SAVEHIST="100000"
export KEYTIMEOUT=1
setopt share_history
setopt hist_ignore_dups
setopt EXTENDED_HISTORY

alias l='ls -ltrG'
alias ls='ls -G'
alias la='ls -laG'
alias ll='ls -lG'
alias git-wc='git ls-files | xargs -n1 git --no-pager blame -w | wc'
alias git-lg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias git-lga="git log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias save="pwd > $HOME/.cache/saved_path"
alias load="cat $HOME/.cache/saved_path | xargs cd"

if type nvim > /dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi

autoload -Uz compinit
compinit

setopt auto_param_slash
setopt mark_dirs
setopt list_types
setopt auto_menu
setopt auto_param_keys
setopt extended_glob
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history
zstyle ':completion:*:messages' format '%F{YELLOW}%d'$DEFAULT
zstyle ':completion:*:warnings' format '%F{RED}No matches for:''%F{YELLOW} %d'$DEFAULT
zstyle ':completion:*:descriptions' format '%F{YELLOW}completing %B%d%b'$DEFAULT
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'$DEFAULT
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-separator '-->'
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

function _ssh {
  hosts=$(register_ssh "$HOME/.ssh/config" | uniq | sort | tr '\n' ' ')
  for host (${(z)hosts}) compadd $host
}

function register_ssh {
  if [ ! -f "$1" ]; then
    return
  fi
  echo "$(fgrep 'Host ' $1 | awk '{print $2}' | sort)";
  includes="$(fgrep 'Include ' $1 | awk '{print $2}' | xargs -I % sh -c 'echo %' | tr '\n' ' ')";
  for include (${(z)includes}) {
    cd "$(dirname $1)"
    cd "$(dirname $include)"
    register_ssh "$(pwd)/$(basename $include)"
  }
}

case ${OSTYPE} in
  darwin*)
    alias netstat-lntp='lsof -nP -iTCP -sTCP:LISTEN'
    alias top='top -u -s5'
    alias c='pbpaste | vipe | pbcopy'
    alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
    ;;
  linux*)
    alias open='xdg-open'
    ;;
esac

if type docker > /dev/null 2>&1; then
  alias redis='docker run -p 127.0.0.1:6379:6379 -d --rm --name redis redis'
  alias mysqld='docker run -p 127.0.0.1:3306:3306 -d --rm --name mysql -e MYSQL_ROOT_PASSWORD=pass mysql'
  if type mysql > /dev/null 2>&1; then
    alias mysql_='mysql -h 127.0.0.1 -u root --password=pass'
  fi
  alias docker-mongo='docker run -p 127.0.0.1:27017:27017 -d --rm --name mongo mongo'
  alias docker-mongo-express='docker run -p 127.0.0.1:8081:8081 -d --rm --name mongo-express --link mongo:mongo mongo-express'
fi
