export LANG=ja_JP.UTF-8

precmd() {
  if [ -x "`which md5sum 2>/dev/null`" ]; then
    local HOSTCOLOR=$'\e[38;05;'"$(printf "%d\n" 0x$(hostname|md5sum|cut -c1-2))"'m'
  elif [ -x "`which md5 2>/dev/null`" ]; then
    local HOSTCOLOR=$'\e[38;05;'"$(printf "%d\n" 0x$(hostname|md5|cut -c1-2))"'m'
  else
    local HOSTCOLOR=$'\e[0m'
  fi
  print -P "\n%n@$HOSTCOLOR%m\e[m %."
}

export PROMPT="> %F{green}$%f "
export PROMPT2="> "

alias l='ls -ltrG'
alias ls='ls -G'
alias la='ls -laG'
alias ll='ls -lG'
alias git-wc='git ls-files | xargs -n1 git --no-pager blame -w | wc'

#REPORTTIME=10

# 補完
autoload -Uz compinit
compinit

setopt auto_param_slash
setopt mark_dirs
setopt list_types
setopt auto_menu
setopt auto_param_keys
setopt extended_glob
zstyle ':completion:*:default' menu select=2

# SSH補完
function _ssh {
  compadd `fgrep 'Host ' ~/.ssh/config | awk '{print $2}' | sort`;
}

case ${OSTYPE} in
  darwin*)
    alias netstat-lntp='lsof -nP -iTCP -sTCP:LISTEN'
    alias o='open ./'
    alias top='top -u -s5'
    alias c='pbpaste | vipe | pbcopy'
    alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
    ;;
  linux*)
    ;;
esac

if [ -x "`which docker 2>/dev/null`" ]; then
  alias redis='docker run -p 127.0.0.1:6379:6379 -d --rm --name redis redis'
  alias mysqld='docker run -p 127.0.0.1:3306:3306 -d --rm --name mysql -e MYSQL_ROOT_PASSWORD=pass mysql'
  alias mongo='docker run -p 127.0.0.1:27017:27017 -d --rm --name mongo mongo'
  alias mongo-express='docker run -p 127.0.0.1:8081:8081 -d --rm --name mongo-express --link mongo:mongo mongo-express'
  alias ubuntu='docker run -it --rm --name ubuntu -v $HOME/ubuntu/:/root/ clenous/ubuntu /bin/bash'
  alias docker-update="docker images | cut -d ' ' -f1 | tail -n +2 | sort | uniq | egrep -v '^(<none>)$' | xargs -P8 -L1 docker pull"
  alias minio='docker run -p 9000:9000 --rm --name minio minio/minio server /data'
  case ${OSTYPE} in
    darwin*)
      alias docker-rmv='docker volume ls -qf dangling=true | xargs docker volume rm'
      ;;
    linux*)
      alias docker-rmv='docker volume ls -qf dangling=true | xargs -r docker volume rm'
      ;;
  esac
fi

if [ -x "`which python 2>/dev/null`" ]; then
  alias http='python -m http.server 3000'
fi

if [ -e "$HOME/.zshrc.local" ]; then
  . "$HOME/.zshrc.local"
fi
