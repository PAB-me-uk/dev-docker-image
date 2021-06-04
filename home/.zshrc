# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/dev/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Prompt config
# Load version control information
autoload -Uz vcs_info
precmd() { vcs_info }

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' formats '%b'

# Set up the prompt (with git branch name)
PROMPT='%n in ${PWD/#$HOME/~} ${vcs_info_msg_0_} > '

setopt prompt_subst

  # Linux
DIVIDER='%F{magenta}|%F{blue}'
COLON=':%F{cyan}'
PROMPT="%K{235}${DIVIDER}%F{cyan}%T${DIVIDER}path${COLON}%~${DIVIDER}aws${COLON}\${AWSUME_PROFILE}${DIVIDER}git${COLON}\${vcs_info_msg_0_}${DIVIDER}?${COLON}%?${DIVIDER}
%k%F{green}$%f "

if [[ -d ~/.zsh-extra ]]; then
  for f in ~/.zsh-extra/*; do source $f; done
fi


# Install vscode extensions (once only)
if [[ -f /tmp/dependencies/extensions.txt ]]
  then
  while IFS="" read -r p || [ -n "$p" ]
  do
    if [[ ! -z "$p" ]]
      then
        code --install-extension $p
    fi
  done < /tmp/dependencies/extensions.txt
  sudo rm /tmp/dependencies/extensions.txt
fi

export PATH="/home/dev/.local/bin/:$PATH"
fixgit

SSH_AGENT_LINES=$(ps aux | grep ssh-agent | grep -v "<defunct>" | wc -l)
if [ "2" -gt $SSH_AGENT_LINES ] ; then
    ssh-agent -s | grep -v echo > ~/.ssh-env-vars
fi
. ~/.ssh-env-vars

cd /workspace/
