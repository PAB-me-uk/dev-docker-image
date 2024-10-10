export USER=dev

# History configuration.
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
unsetopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY
unsetopt EXTENDED_HISTORY

# Keybinding.
bindkey -e # Emacs mode change to -v for vim mode.

# Configure auto completions.
zstyle :compinstall filename '/home/dev/.zshrc'
autoload -Uz compinit

# Add autosuggestions.
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Prompt config.

## Load version control information.
autoload -Uz vcs_info
precmd() { vcs_info }

## Format the vcs_info_msg_0_ variable.
zstyle ':vcs_info:git:*' formats '%b'

## Set up the prompt (with git branch name).
PROMPT='%n in ${PWD/#$HOME/~} ${vcs_info_msg_0_} > '
setopt prompt_subst
DIVIDER='%F{magenta}|%F{blue}'
COLON=':%F{cyan}'
PROMPT="%K{235}${DIVIDER}%F{cyan}%T${DIVIDER}path${COLON}%~${DIVIDER}aws${COLON}\${AWSUME_PROFILE}${DIVIDER}git${COLON}\${vcs_info_msg_0_}${DIVIDER}?${COLON}%?${DIVIDER}
%k%F{green}$%f "

# Install vscode extensions.
tsp /usr/local/bin/install-vscode-extensions.sh > /dev/null

# Configure path.
export PATH="/home/dev/.local/bin/:$PATH"

# Copy Python to workspace if required.
. python-to-workspace

# Fix VSCodes tamperign with git config.
fixgit

# Start SSH Agent.
SSH_AGENT_LINES=$(ps aux | grep ssh-agent | grep -v "<defunct>" | wc -l)
if [ "2" -gt $SSH_AGENT_LINES ] ; then
    ssh-agent -s | grep -v echo > ~/.ssh-env-vars
fi
. ~/.ssh-env-vars

# Aliases.
alias j=just
alias dc='just --justfile "${HOME}/.local/share/just/dc/.justfile"'
alias docker="sudo docker"

# Run any extra scripts.
if [[ -d ~/.zsh-extra ]]; then
  for f in ~/.zsh-extra/*; do source $f; done
fi

# FZF Keybindings
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh

compinit # Must be before nvm bash completion.

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
