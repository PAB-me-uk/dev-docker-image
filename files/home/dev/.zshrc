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
tsp dc install-vscode-extensions > /dev/null

# Configure path.
export PATH="/home/dev/.local/bin:$PATH"

# Copy Python to workspace if required.
__venv_path_activate=${IMAGE_WORKSPACE_DIR}/.python/${IMAGE_PYTHON_VERSION}/bin/activate

VIRTUAL_ENV_DISABLE_PROMPT=1

if [ ! -f ${__venv_path_activate} ]; then
  echo "Relocating Python dependencies to workspace"
  mv ${IMAGE_WORKSPACE_TEMPLATE_DIR}/.python/${IMAGE_PYTHON_VERSION} ${IMAGE_WORKSPACE_DIR}/.python
fi

. ${__venv_path_activate}

unset __venv_path_activate

# Fix VSCodes tampering with git config.
if git config --system credential.helper| grep -q 'vscode'; then
  sudo git config --system --unset credential.helper
fi

if git config --global credential.helper| grep -q 'vscode'; then
  git config --global credential.helper "!aws codecommit credential-helper \$@"
  git config --global credential.UseHttpPath true
fi

# Start SSH Agent.
SSH_AGENT_LINES=$(ps aux | grep ssh-agent | grep -v "<defunct>" | wc -l)
if [ "2" -gt $SSH_AGENT_LINES ] ; then
    ssh-agent -s | grep -v echo > ~/.ssh-env-vars
fi
. ~/.ssh-env-vars

# Aliases.
alias j=just
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
