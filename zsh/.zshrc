export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

export EDITOR='nvim'



export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  

eval "$(starship init zsh)"


export PATH=/home/rahularya/.opencode/bin:$PATH



nvim_copilot_sync() {
  local opencode_token=$(jq -r '.["github-copilot"].refresh' ~/.local/share/opencode/auth.json 2>/dev/null)
  if [ -n "$opencode_token" ] && [ "$opencode_token" != "null" ]; then
    local apps_json="$HOME/.config/github-copilot/apps.json"
    if [ -f "$apps_json" ]; then
      local tmp=$(mktemp)
      jq --arg token "$opencode_token" '."github.com:Iv1.b507a08c87ecfe98".oauth_token = $token' "$apps_json" > "$tmp" && mv "$tmp" "$apps_json"
    fi
  fi
  command nvim "$@"
}
alias nvim=nvim_copilot_sync
