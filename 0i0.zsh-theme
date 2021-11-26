# ˚
CURRENT_BG='NONE'
PRIMARY_FG=black

# Characters
SEGMENT_SEPARATOR="\ue0b0"
PLUSMINUS="\u00b1"
BRANCH="\ue702"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  print -n "%{%k%}"
  print -n "%{%f%}"
  CURRENT_BG=''
}

###############################################################################
# Begin sections
# E.g prompt
# <cwd>  <git> [<python_version>]
# <prompt prefix> |
###############################################################################

### Prompt components
# Each component will draw itself, and hide itself if no information needs to
# be shown.

# Dir: current working directory
prompt_dir() {
  prompt_segment CURRENT_BG 12 '%U%2~%u '
}

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref symbol maxchars suffix
  maxchars=38
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"

  if [[ -n "$ref" ]]; then
    if is_dirty; then
      color=11
      symbol="$PLUSMINUS"
    else
      color=10
      symbol=""
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      b="$BRANCH"
    else
      b="$DETACHED"
    fi
    [[ "${#ref}" -gt "$maxchars" ]] && suffix="..." || suffix=""
    prompt_segment CURRENT_BG 9 "$b "
    prompt_segment CURRENT_BG $color "${ref:0:$maxchars}$suffix "
    prompt_segment CURRENT_BG $color "$symbol "
  fi
}

# Sofware version: global or virtualenv
# node
prompt_software_version() {
  local prefix=""
  if [[ -n $VIRTUAL_ENV ]]; then
    prefix="$(basename $VIRTUAL_ENV) // "
  fi

  local py_version=${$(python3 --version 2>/dev/null | cut -d ' ' -f 2)}
  prompt_segment CURRENT_BG 14 "[$prefix$py_version] "

  #: Show node version when there's a package.json file in cwd
  if [[ -f package.json ]]; then
    local node_version=${$(node --version 2>/dev/null)}
    prompt_segment CURRENT_BG 14 "[node:$node_version] "
  fi
}

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment CURRENT_BG 8 "$user@%m "
  fi
}

prompt_new_line() {
  prompt_segment CURRENT_BG default "\n"
}

prompt_prompt() {
  local color=13
  [[ $RETVAL -ne 0 ]] && color=9
  prompt_segment CURRENT_BG $color "%(!.#.Ψ) "
}

## Main prompt
top_left () {
  prompt_dir
  prompt_git
}

top_right () {
  prompt_software_version
}

prompt_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
  local left="$(top_left)"
  local right="$(top_right)"
  print -n "$left$(get_space $left $right)$right"
  prompt_new_line
  prompt_prompt
  prompt_end
}

right_prompt_main() {
  prompt_context
}

prompt_precmd() {
  vcs_info
  PROMPT='$(prompt_main)'
  RPROMPT='$(right_prompt_main)'
}

prompt_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_precmd

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '(%b|%a%u%c)'
}

function get_space {
    local str=$1$2
    local zero='%([BSUbfksu]|([FB]|){*})'
    local len=${#${(S%%)str//$~zero/}}
    local size=$(( $COLUMNS - $len - 1 ))
    local space=""
    while [[ $size -gt 0 ]]; do
        space="$space "
        let size=$size-1
    done
    echo $space
}

prompt_setup "$@"
