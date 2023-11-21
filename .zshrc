# Use powerline
USE_POWERLINE="true"
# Has weird character width
# Example:
#    is not a diamond
HAS_WIDECHARS="false"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi

alias open23='cd ~/dev/open23'
alias gs='git status'
alias gap='git add -p'
alias gup='git fetch && git pull'
alias gaa='git add .'
alias gpf='git push -f'
alias gca='git commit --amend'
alias ll='ls -alF'
