nano ~/starship_safe_prompt.sh
# paste everything below
source ~/starship_safe_prompt.sh


# ==================================================
# SAFE STARSHIP-STYLE BASH PROMPT (NO DEPENDENCIES)
# ==================================================

# ---------- CONFIG ----------
PROMPT_THEME="dark"      # dark | light
COMPACT_MODE=1           # 1 = one-line | 0 = multiline
SHOW_EXIT=0
SHOW_EXETIME=1
SHOW_ADMIN=1

TIME_FMT_24="%H:%M:%S"
TIME_FMT_24_HM="%H:%M"

# Time zones (TZ|LABEL)
TIMEZONES=(
  "Asia/Kolkata|IST"
  "Asia/Seoul|KST"
)

# ---------- COLORS ----------
if [[ "$PROMPT_THEME" == "dark" ]]; then
  C_USER="\[\e[36m\]"
  C_PATH="\[\e[33m\]"
  C_TIME="\[\e[36m\]"
  C_EXIT="\[\e[31m\]"
  C_ADMIN="\[\e[31m\]"
else
  C_USER="\[\e[34m\]"
  C_PATH="\[\e[33m\]"
  C_TIME="\[\e[34m\]"
  C_EXIT="\[\e[31m\]"
  C_ADMIN="\[\e[31m\]"
fi
C_RESET="\[\e[0m\]"

# ---------- SYMBOLS (NERD FONT SAFE) ----------
SYM_ARROW="❯"
SYM_FOLDER=""
SYM_CLOCK=""
SYM_LINUX=""
SYM_ADMIN=""

# ---------- EXECUTION TIME ----------
__cmd_start_time=0
trap '__cmd_start_time=$(date +%s%3N)' DEBUG

__exec_time() {
  local end=$(date +%s%3N)
  local diff=$((end - __cmd_start_time))
  (( diff > 150 )) && echo "${diff}ms"
}

# ---------- HELPERS ----------
short_path() {
  local p="${PWD/#$HOME/~}"
  [[ ${#p} -le 45 ]] && echo "$p" && return
  echo "...${p: -42}"
}

tz_time() {
  local out=()
  for z in "${TIMEZONES[@]}"; do
    IFS='|' read -r id label <<< "$z"
    t=$(TZ="$id" date +"$TIME_FMT_24_HM" 2>/dev/null) &&
      out+=("$t $label")
  done
  local joined="${out[*]}"
  echo "${joined// / | }" | sed 's/ | $//'
}

is_admin() {
  [[ $EUID -eq 0 ]]
}

# ---------- PROMPT ----------
__build_prompt() {
  local exit_code=$?
  local exec_time=""
  [[ $SHOW_EXETIME -eq 1 ]] && exec_time=$(__exec_time)

  local user_host="$USER@$(hostname)"
  local path="$(short_path)"
  local timezones="$(tz_time)"

  PS1=""

  if [[ $COMPACT_MODE -eq 1 ]]; then
    PS1+="$C_USER$SYM_LINUX $user_host "
    PS1+="$C_PATH$SYM_FOLDER $path "
    [[ -n "$timezones" ]] && PS1+="$C_TIME$SYM_CLOCK $timezones "
    [[ $SHOW_EXIT -eq 1 && $exit_code -ne 0 ]] && PS1+="$C_EXIT exit:$exit_code "
    [[ -n "$exec_time" ]] && PS1+="$C_TIME$exec_time "
    [[ $SHOW_ADMIN -eq 1 && $(is_admin) ]] && PS1+="$C_ADMIN$SYM_ADMIN "
    PS1+="$C_USER$SYM_ARROW $C_RESET"
  else
    PS1="$C_USER$SYM_LINUX $user_host
$C_PATH$SYM_FOLDER $path
$C_TIME$SYM_CLOCK $timezones
$C_USER$SYM_ARROW $C_RESET"
  fi
}

PROMPT_COMMAND="__build_prompt"

# ---------- COMMANDS ----------
alias ll='ls -lah'
alias la='ls -a'
alias grep='grep --color=auto'
alias df='df -h'
alias which='command -v'
alias reload='source ~/.bashrc'

# ---------- TOGGLES ----------
compact-on()  { COMPACT_MODE=1; }
compact-off() { COMPACT_MODE=0; }

theme-dark()  { PROMPT_THEME="dark"; reload; }
theme-light() { PROMPT_THEME="light"; reload; }

clear
echo "Welcome $USER"
