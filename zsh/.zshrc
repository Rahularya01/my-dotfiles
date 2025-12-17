export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

export EDITOR='nvim'



export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  



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

export PATH="$HOME/.tmuxifier/bin:$PATH"

alias nvim=nvim_copilot_sync


sesh-selector() {
  selection="$(sesh list --icons \
    | fzf --no-sort --ansi --border-label " 󰆍 Sessions " \
    --prompt " ❯ " \
    --header "^a all ^t tmux ^x zoxide ^g configs | ^k delete" \
    --bind "ctrl-a:change-prompt( ❯ )+reload(sesh list --icons)" \
    --bind "ctrl-t:change-prompt(󰆍 ❯ )+reload(sesh list -t --icons)" \
    --bind "ctrl-x:change-prompt(󰉋 ❯ )+reload(sesh list -z --icons)" \
    --bind "ctrl-g:change-prompt( ❯ )+reload(sesh list -c --icons)" \
    --bind "ctrl-k:execute-silent(tmux kill-session -t {-1})+reload(sesh list --icons)" \
    --color "fg:#ebdbb2,bg:#282828,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f" \
    --color "info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54" \
    --pointer "▶" --marker "✓" \
    --layout reverse --info inline \
    | awk '{print $NF}')"
  [ -n "$selection" ] && sesh connect "$selection" || true
}


alias ss='sesh-selector'


eval "$(starship init zsh)"
export PATH="$HOME/go/bin:$PATH"
eval "$(zoxide init zsh)"
