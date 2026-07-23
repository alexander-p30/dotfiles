#!/usr/bin/env bash
# moka — a colorful caffeinate wrapper TUI for macOS.
#
# Manages a single "keep-awake" caffeinate session:
#   permanent  -> caffeinate -sumi
#   timed      -> caffeinate -sumit <seconds>
# Shows a live hh:mm:ss clock (countdown for timed, elapsed for permanent),
# adjustable in 1h / 30m / 1m grains (Shift subtracts). Quitting the TUI can
# leave caffeinate running; only stop/quit+stop kill it.
set -uo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
MOKA_MIN_SECONDS=60       # 1 minute floor for the timed buffer
MOKA_MAX_SECONDS=356400   # 99h cap (keeps hours two-digit)
MOKA_DEFAULT_BUFFER=1800  # 30 minutes default when composing a timed session
MOKA_INNER=43             # inner width of the box (between the borders)
: "${MOKA_STATE_FILE:=${XDG_CACHE_HOME:-$HOME/.cache}/moka/state}"
: "${MOKA_CAFFEINATE:=caffeinate}"  # overridable for testing
declare -gA MOKA_CWD_CACHE          # pid -> cwd (a process's cwd is stable)

# ---------------------------------------------------------------------------
# Pure logic (unit-tested in tests/moka_test.sh)
# ---------------------------------------------------------------------------

# Format a non-negative second count as hh:mm:ss (hours grow past 2 digits).
moka_fmt_hms() {
  local s=$1
  ((s < 0)) && s=0
  printf '%02d:%02d:%02d' $((s / 3600)) $(((s % 3600) / 60)) $((s % 60))
}

# Format a positive second count coarsely for a glanceable indicator:
# >=1h -> "1h24m" (minutes omitted when zero, e.g. "1h"); >=1m -> "12m"; else "<1m".
moka_fmt_coarse() {
  local s=$1
  ((s < 0)) && s=0
  if ((s >= 3600)); then
    local h=$((s / 3600)) m=$(((s % 3600) / 60))
    if ((m > 0)); then printf '%dh%dm' "$h" "$m"; else printf '%dh' "$h"; fi
  elif ((s >= 60)); then
    printf '%dm' $((s / 60))
  else
    printf '<1m'
  fi
}

# Build the herdr sidebar token (empty = idle). A managed session takes
# precedence; otherwise an unmanaged caffeinate is flagged with ⚠.
#   moka_status_token <managed_mode> <managed_remaining> <unmanaged_present> <unmanaged_remaining>
moka_status_token() {
  local mode=$1 rem=${2:-0} un=${3:-0} un_rem=${4:-}
  case "$mode" in
    timed) printf '☕ %s' "$(moka_fmt_coarse "$rem")"; return ;;
    permanent) printf '☕ ∞'; return ;;
  esac
  if ((un)); then
    if [[ -n "$un_rem" ]]; then
      printf '☕⚠ %s' "$(moka_fmt_coarse "$un_rem")"
    else
      printf '☕⚠'
    fi
  fi
  # idle: print nothing
}

# Adjust a duration buffer by delta seconds, clamped to [MIN, MAX].
moka_buffer_adjust() {
  local new=$(($1 + $2))
  ((new < MOKA_MIN_SECONDS)) && new=$MOKA_MIN_SECONDS
  ((new > MOKA_MAX_SECONDS)) && new=$MOKA_MAX_SECONDS
  printf '%d' "$new"
}

# remaining(end, now) -> max(0, end - now)
moka_remaining() {
  local r=$(($1 - $2))
  ((r < 0)) && r=0
  printf '%d' "$r"
}

# elapsed(start, now) -> max(0, now - start)
moka_elapsed() {
  local e=$(($2 - $1))
  ((e < 0)) && e=0
  printf '%d' "$e"
}

# Truncate to a max width, keeping the tail (ellipsis on the left).
moka_trunc_tail() { # text max
  local t=$1 max=$2 n
  ((${#t} <= max)) && {
    printf '%s' "$t"
    return
  }
  n=$((max - 1))
  ((n < 0)) && n=0
  printf '…%s' "${t: -n}"
}

# Parse a `ps -o etime` value ([[dd-]hh:]mm:ss) into seconds.
moka_parse_etime() {
  local e=${1// /} days=0 rest a b c h=0 m=0 s=0
  [[ -z "$e" ]] && {
    printf '0'
    return
  }
  if [[ "$e" == *-* ]]; then days=${e%%-*} rest=${e#*-}; else rest=$e; fi
  IFS=: read -r a b c <<<"$rest"
  if [[ -n "$c" ]]; then h=$a m=$b s=$c; else m=$a s=$b; fi
  printf '%d' $((10#${days:-0} * 86400 + 10#${h:-0} * 3600 + 10#${m:-0} * 60 + 10#${s:-0}))
}

# Extract a caffeinate -t timeout (seconds) from a flags string; empty if none.
moka_extract_timeout() {
  local tok last="" has_t=0
  for tok in $1; do
    [[ "$tok" == -*t* ]] && has_t=1
    [[ "$tok" =~ ^[0-9]+$ ]] && last=$tok
  done
  ((has_t)) && printf '%s' "$last"
}

# Replace a leading $HOME in a path with ~.
moka_abbrev_home() {
  local p=$1
  if [[ "$p" == "$HOME" ]]; then
    printf '~'
  elif [[ "$p" == "$HOME"/* ]]; then
    printf '~%s' "${p#"$HOME"}"
  else
    printf '%s' "$p"
  fi
}

# Map (screen, raw key) to an action token. Enter is "", Esc is $'\e'.
moka_key_to_action() {
  local screen=$1 key=$2
  case "$screen" in
    idle)
      case "$key" in
        p) echo start_permanent ;;
        t) echo goto_setup ;;
        x) echo goto_manage ;;
        o) echo toggle_oneline ;;
        q | Q) echo quit ;;
        *) echo none ;;
      esac
      ;;
    setup)
      case "$key" in
        h) echo add_h ;;
        H) echo sub_h ;;
        m) echo add_m ;;
        M) echo sub_m ;;
        i) echo add_i ;;
        I) echo sub_i ;;
        o) echo toggle_oneline ;;
        "" | $'\n' | $'\r') echo commit ;;
        $'\e') echo cancel ;;
        *) echo none ;;
      esac
      ;;
    timed)
      case "$key" in
        t) echo goto_setup ;;
        p) echo switch_permanent ;;
        x) echo goto_manage ;;
        o) echo toggle_oneline ;;
        s) echo stop ;;
        q) echo quit_keep ;;
        Q) echo quit_stop ;;
        *) echo none ;;
      esac
      ;;
    permanent)
      case "$key" in
        t) echo goto_setup ;;
        x) echo goto_manage ;;
        o) echo toggle_oneline ;;
        s) echo stop ;;
        q) echo quit_keep ;;
        Q) echo quit_stop ;;
        *) echo none ;;
      esac
      ;;
    manage)
      case "$key" in
        j | __down__) echo move_down ;;
        k | __up__) echo move_up ;;
        o) echo toggle_oneline ;;
        x) echo ask_terminate ;;
        $'\e') echo back ;;
        *) echo none ;;
      esac
      ;;
    manage_confirm)
      # Destructive confirm: only an explicit yes kills; anything else cancels.
      case "$key" in
        y | Y) echo confirm_terminate ;;
        *) echo cancel_terminate ;;
      esac
      ;;
    *) echo none ;;
  esac
}

# Given whether a shared session is alive, its mode, and the current screen,
# return the screen this window should show. Running/idle screens adopt the
# shared session; modal screens (setup/manage) are left alone.
moka_reconcile_screen() { # alive mode screen
  local alive=$1 mode=$2 screen=$3
  if (($1)); then
    case "$screen" in
      idle | timed | permanent) printf '%s' "$mode" ;;
      *) printf '%s' "$screen" ;;
    esac
  else
    case "$screen" in
      timed | permanent) printf 'idle' ;;
      *) printf '%s' "$screen" ;;
    esac
  fi
}

# ---------------------------------------------------------------------------
# State file (hybrid tracking) — also unit-tested
# ---------------------------------------------------------------------------

moka_state_write() { # mode pid start [end]
  mkdir -p "$(dirname "$MOKA_STATE_FILE")"
  {
    printf 'mode=%s\n' "$1"
    printf 'pid=%s\n' "$2"
    printf 'start=%s\n' "$3"
    printf 'end=%s\n' "${4:-}"
  } >"$MOKA_STATE_FILE"
}

# Populate MOKA_MODE/MOKA_PID/MOKA_START/MOKA_END. Returns 1 if no state file.
moka_state_read() {
  [[ -f "$MOKA_STATE_FILE" ]] || return 1
  MOKA_MODE=""
  MOKA_PID=""
  MOKA_START=""
  MOKA_END=""
  local key val
  while IFS='=' read -r key val; do
    case "$key" in
      mode) MOKA_MODE=$val ;;
      pid) MOKA_PID=$val ;;
      start) MOKA_START=$val ;;
      end) MOKA_END=$val ;;
    esac
  done <"$MOKA_STATE_FILE"
  return 0
}

moka_state_clear() {
  rm -f "$MOKA_STATE_FILE"
}

# ---------------------------------------------------------------------------
# Process management
# ---------------------------------------------------------------------------

moka_now() { printf '%s\n' "${MOKA_NOW:-$(date +%s)}"; }

# True if pid is a live caffeinate process.
moka_pid_is_caffeinate() {
  local pid=${1:-}
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  local comm
  comm=$(ps -o comm= -p "$pid" 2>/dev/null) || return 1
  [[ "$comm" == *caffeinate* ]]
}

# List all caffeinate pids we did NOT start (one per line).
moka_unmanaged_list() {
  local pids p
  pids=$(pgrep -x caffeinate 2>/dev/null) || return 0
  for p in $pids; do
    [[ "$p" == "${MOKA_PID:-}" ]] && continue
    printf '%s\n' "$p"
  done
}

# Echo the pid of a caffeinate we did NOT start, if any.
moka_find_unmanaged() { moka_unmanaged_list | head -1; }

# Working directory of a process (via lsof), cached — cwd is stable per pid.
moka_proc_cwd() {
  local pid=$1 cwd
  if [[ -n "${MOKA_CWD_CACHE[$pid]:-}" ]]; then
    printf '%s' "${MOKA_CWD_CACHE[$pid]}"
    return
  fi
  cwd=$(lsof -a -d cwd -p "$pid" -Fn 2>/dev/null | sed -n 's/^n//p' | head -1)
  if [[ -n "$cwd" ]]; then
    MOKA_CWD_CACHE[$pid]=$cwd
    printf '%s' "$cwd"
  else
    printf '?'
  fi
}

# The caffeinate arguments of a process (e.g. "-sumit 3600").
moka_proc_args() {
  local cmd
  cmd=$(ps -o args= -p "$1" 2>/dev/null) || return 0
  cmd=${cmd#*caffeinate}
  printf '%s' "${cmd# }"
}

# Elapsed seconds a process has been running.
moka_etime_seconds() { moka_parse_etime "$(ps -o etime= -p "$1" 2>/dev/null)"; }

# A timer label for an unmanaged caffeinate: countdown if it has -t, else ∞ elapsed.
moka_proc_timer() {
  local pid=$1 elapsed timeout
  elapsed=$(moka_etime_seconds "$pid")
  timeout=$(moka_extract_timeout "$(moka_proc_args "$pid")")
  if [[ -n "$timeout" ]]; then
    printf '%s' "$(moka_fmt_hms "$(moka_remaining "$timeout" "$elapsed")")"
  else
    printf '∞ %s' "$(moka_fmt_hms "$elapsed")"
  fi
}

# Kill the currently managed session (if alive) and clear runtime state.
moka_stop_process() {
  if [[ -n "${MOKA_PID:-}" ]] && kill -0 "$MOKA_PID" 2>/dev/null; then
    kill "$MOKA_PID" 2>/dev/null || true
  fi
  moka_state_clear
  MOKA_MODE=""
  MOKA_PID=""
  MOKA_START=""
  MOKA_END=""
}

moka_start_permanent() {
  moka_stop_process
  nohup "$MOKA_CAFFEINATE" -sumi >/dev/null 2>&1 &
  local pid=$!
  disown 2>/dev/null || true
  local now
  now=$(moka_now)
  moka_state_write permanent "$pid" "$now"
  MOKA_MODE=permanent
  MOKA_PID=$pid
  MOKA_START=$now
  MOKA_END=""
}

moka_start_timed() { # seconds
  local secs=$1
  moka_stop_process
  nohup "$MOKA_CAFFEINATE" -sumit "$secs" >/dev/null 2>&1 &
  local pid=$!
  disown 2>/dev/null || true
  local now
  now=$(moka_now)
  moka_state_write timed "$pid" "$now" "$((now + secs))"
  MOKA_MODE=timed
  MOKA_PID=$pid
  MOKA_START=$now
  MOKA_END=$((now + secs))
}

# ---------------------------------------------------------------------------
# Non-interactive status (for the herdr sidebar reporter / scripting)
# ---------------------------------------------------------------------------

# Print a compact keep-awake indicator. `--format sidebar` emits the herdr
# token (empty when idle); default emits a human line. Exit 0 if a keep-awake
# is active, 1 if idle. Never enters the TUI and needs no tty.
moka_status_cmd() {
  local fmt="human"
  while (($#)); do
    case "$1" in
      --format) fmt=${2:-human}; shift 2 ;;
      --sidebar) fmt=sidebar; shift ;;
      *) shift ;;
    esac
  done

  if [[ "$fmt" == list ]]; then
    moka_status_list
    return
  fi

  local now mode="" rem=0 un_present=0 un_rem="" u
  now=$(moka_now)

  if moka_state_read && moka_pid_is_caffeinate "${MOKA_PID:-}"; then
    if [[ "$MOKA_MODE" == timed ]]; then
      rem=$(moka_remaining "${MOKA_END:-0}" "$now")
      ((rem > 0)) && mode=timed
    elif [[ "$MOKA_MODE" == permanent ]]; then
      mode=permanent
    fi
  fi

  u=$(moka_find_unmanaged)
  if [[ -n "$u" ]]; then
    un_present=1
    local to
    to=$(moka_extract_timeout "$(moka_proc_args "$u")")
    [[ -n "$to" ]] && un_rem=$(moka_remaining "$to" "$(moka_etime_seconds "$u")")
  fi

  local token
  token=$(moka_status_token "$mode" "$rem" "$un_present" "$un_rem")

  if [[ "$fmt" == sidebar ]]; then
    printf '%s' "$token"
    [[ -n "$token" ]]
    return
  fi

  if [[ "$mode" == timed ]]; then
    printf 'timed · %s remaining · pid %s\n' "$(moka_fmt_coarse "$rem")" "${MOKA_PID:-?}"
  elif [[ "$mode" == permanent ]]; then
    printf 'permanent · pid %s\n' "${MOKA_PID:-?}"
  elif ((un_present)); then
    if [[ -n "$un_rem" ]]; then
      printf 'unmanaged · %s remaining · pid %s\n' "$(moka_fmt_coarse "$un_rem")" "$u"
    else
      printf 'unmanaged · pid %s\n' "$u"
    fi
  else
    printf 'idle\n'
    return 1
  fi
  return 0
}

# Enumerate every active caffeinate as `<cwd>\t<token>` lines (one per process),
# so a workspace-aware reporter can attribute each to a space by its directory.
# The managed session (if any) is listed with its ☕ token; every other
# caffeinate is listed as unmanaged (☕⚠). Processes whose cwd can't be resolved
# are emitted with cwd "?" and left for the caller to skip.
moka_status_list() {
  local now; now=$(moka_now)

  if moka_state_read && moka_pid_is_caffeinate "${MOKA_PID:-}"; then
    local token=""
    if [[ "$MOKA_MODE" == timed ]]; then
      local rem; rem=$(moka_remaining "${MOKA_END:-0}" "$now")
      ((rem > 0)) && token=$(moka_status_token timed "$rem" 0 "")
    elif [[ "$MOKA_MODE" == permanent ]]; then
      token=$(moka_status_token permanent 0 0 "")
    fi
    [[ -n "$token" ]] && printf '%s\t%s\n' "$(moka_proc_cwd "$MOKA_PID")" "$token"
  fi

  local p
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    local to rem token
    to=$(moka_extract_timeout "$(moka_proc_args "$p")")
    if [[ -n "$to" ]]; then
      rem=$(moka_remaining "$to" "$(moka_etime_seconds "$p")")
      token=$(moka_status_token "" 0 1 "$rem")
    else
      token=$(moka_status_token "" 0 1 "")
    fi
    printf '%s\t%s\n' "$(moka_proc_cwd "$p")" "$token"
  done < <(moka_unmanaged_list)
}

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
moka_setup_colors() {
  if [[ -n "${NO_COLOR:-}" ]] || [[ "${TERM:-}" == "dumb" ]] || [[ ! -t 1 ]]; then
    C_RESET="" C_BOLD="" C_DIM=""
    COL_SLATE="" COL_AMBER="" COL_TEAL="" COL_ORANGE="" COL_RED="" COL_KEY=""
    return
  fi
  C_RESET=$'\e[0m'
  C_BOLD=$'\e[1m'
  C_DIM=$'\e[2m'
  COL_SLATE=$'\e[38;2;148;163;184m'  # idle
  COL_AMBER=$'\e[38;2;251;191;36m'   # permanent
  COL_TEAL=$'\e[38;2;45;212;191m'    # timed healthy
  COL_ORANGE=$'\e[38;2;251;146;60m'  # timed < 5 min
  COL_RED=$'\e[38;2;248;113;113m'    # timed < 1 min
  COL_KEY=$'\e[38;2;56;189;248m'     # hotkey accent
}

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

# Visible terminal width of a string in cells. Bash ${#s} counts codepoints, but
# a handful of glyphs we draw in headers/banners are East-Asian-Wide (2 cells):
# ☕ ⏱ ⏰ ⚠. Count each as one extra cell so box borders line up on the right.
moka_vis_width() { # text
  local s=$1 n=${#1} g rem
  for g in "☕" "⏱" "⏰" "⚠"; do
    rem=${s//"$g"/}
    n=$((n + ${#s} - ${#rem}))
  done
  printf '%d' "$n"
}

# Pad text to a fixed visible width, centered (truncates if too long).
moka_center_in() {
  local w=$1 t=$2 len
  len=$(moka_vis_width "$t")
  if ((len >= w)); then
    printf '%s' "${t:0:w}"
    return
  fi
  local total=$((w - len)) l r
  l=$((total / 2))
  r=$((total - l))
  printf '%*s%s%*s' "$l" "" "$t" "$r" ""
}

# "02:15:09" -> "0 2 : 1 5 : 0 9"
moka_space_out() {
  local s=$1 out="" i
  for ((i = 0; i < ${#s}; i++)); do out+="${s:i:1} "; done
  printf '%s' "${out% }"
}

# Append a printf-formatted chunk to the frame buffer (no forks).
moka_app() {
  local fmt=$1
  shift
  local tmp
  # shellcheck disable=SC2059
  printf -v tmp "$fmt" "$@"
  MOKA_OUT+=$tmp
}

moka_move() { moka_app '\e[%d;%dH' "$(($1 + 1))" "$(($2 + 1))"; }

# A bordered content line: row left modecolor contentcolor plaincontent(INNER-wide)
moka_box_line() {
  moka_move "$1" "$2"
  moka_app '%s│%s%s%s%s│%s' "$3" "$4" "$5" "$C_RESET" "$3" "$C_RESET"
}

# Colorize a hint string: bracketed [keys] in the accent, labels dim.
moka_colorize_keys() {
  local plain=$1 out="" i c
  for ((i = 0; i < ${#plain}; i++)); do
    c=${plain:i:1}
    case "$c" in
      "[") out+="${COL_KEY}${C_BOLD}[" ;;
      "]") out+="]${C_RESET}${C_DIM}" ;;
      *) out+="$c" ;;
    esac
  done
  printf '%s%s%s' "$C_DIM" "$out" "$C_RESET"
}

# A hint line, centered on screen at a row (truncated so it never wraps).
moka_hint() { # row plaintext
  local row=$1 plain=$2 hleft
  ((${#plain} > MOKA_COLS)) && plain="${plain:0:MOKA_COLS}"
  hleft=$(((MOKA_COLS - ${#plain}) / 2))
  ((hleft < 0)) && hleft=0
  moka_move "$row" "$hleft"
  moka_app '%s' "$(moka_colorize_keys "$plain")"
}

# A run of n box-drawing dashes.
moka_dashes() {
  local n=$1 i out=""
  for ((i = 0; i < n; i++)); do out+="─"; done
  printf '%s' "$out"
}

# Right-pad to a width by character count (so multibyte glyphs stay aligned,
# unlike printf %-Ns which counts bytes).
moka_pad_right() {
  local s=$1 w=$2 len=${#1}
  if ((len < w)); then
    printf '%s%*s' "$s" $((w - len)) ""
  else
    printf '%s' "$s"
  fi
}

# Left-justify text to a fixed visible width (ellipsis if too long).
moka_ljust_in() {
  local w=$1 t=$2 len=${#2}
  if ((len > w)); then
    printf '%s…' "${t:0:w - 1}"
    return
  fi
  printf '%s%*s' "$t" $((w - len)) ""
}

# Center a plain string on the full screen width at a row, in a given color.
moka_banner() { # row color plaintext
  local row=$1 color=$2 plain=$3 vis bleft
  vis=$(moka_vis_width "$plain")
  bleft=$(((MOKA_COLS - vis) / 2))
  ((bleft < 0)) && bleft=0
  moka_move "$row" "$bleft"
  moka_app '%s%s%s' "$color" "$plain" "$C_RESET"
}

# Resolve the live terminal size into MOKA_LINES / MOKA_COLS. `tput` is unreliable
# here because our stdout is captured in a $(...) so it can't ioctl the terminal;
# stty reads the controlling tty directly and reflows on resize.
moka_termsize() {
  if [[ -n "${MOKA_FORCE_LINES:-}" && -n "${MOKA_FORCE_COLS:-}" ]]; then
    MOKA_LINES=$MOKA_FORCE_LINES MOKA_COLS=$MOKA_FORCE_COLS
    return
  fi
  local sz
  sz=$(stty size </dev/tty 2>/dev/null) || sz=$(stty size 2>/dev/null) || sz=""
  if [[ "$sz" =~ ^[0-9]+" "[0-9]+$ ]]; then
    MOKA_LINES=${sz%% *} MOKA_COLS=${sz##* }
  else
    MOKA_LINES=$(tput lines 2>/dev/null || echo 24)
    MOKA_COLS=$(tput cols 2>/dev/null || echo 80)
  fi
}

moka_draw() { # now
  local now=$1
  moka_termsize
  local box_w=$((MOKA_INNER + 2))
  local left=$(((MOKA_COLS - box_w) / 2))
  ((left < 0)) && left=0

  # Fall back to the compact one-line view when forced (o) or when the pane is
  # too small to fit the full box — otherwise the box overflows and corrupts.
  local need=12
  [[ "$screen" == manage || "$screen" == manage_confirm ]] && need=$((${#MOKA_MANAGE_PIDS[@]} + 6))
  if ((oneline)) || ((MOKA_LINES < need)) || ((MOKA_COLS < box_w)); then
    moka_draw_oneline "$now"
    return
  fi
  if [[ "$screen" == manage || "$screen" == manage_confirm ]]; then
    moka_draw_manage "$now"
    return
  fi

  # Block layout: status(1) box(8) blank(1) hint1(1) hint2(1) = 12 rows.
  local top=$(((MOKA_LINES - 12) / 2))
  ((top < 0)) && top=0

  # Resolve per-screen content.
  local mc header linea lineb ca cb
  local -a hints=()
  case "$screen" in
    idle)
      mc=$COL_SLATE
      header="☕  m o k a"
      linea="no keep-awake running" ca=$mc
      lineb="your mac can sleep" cb=$C_DIM
      hints=("[p] permanent   [t] timed   [x] manage   [o] mini   [q] quit")
      ;;
    setup)
      mc=$COL_TEAL
      header="⏱  timed setup"
      linea=$(moka_space_out "$(moka_fmt_hms "$buf")") ca="$C_BOLD$mc"
      lineb="pending" cb=$C_DIM
      hints=(
        "[h] +1h   [m] +30m   [i] +1m    ⇧ = subtract"
        "[enter] start        [esc] cancel"
      )
      ;;
    timed)
      local rem
      rem=$(moka_remaining "${MOKA_END:-0}" "$now")
      if ((rem < 60)); then
        mc=$COL_RED
      elif ((rem < 300)); then
        mc=$COL_ORANGE
      else
        mc=$COL_TEAL
      fi
      header="⏱  timed · counting down"
      linea=$(moka_space_out "$(moka_fmt_hms "$rem")") ca="$C_BOLD$mc"
      lineb="remaining · pid ${MOKA_PID:-?}" cb=$C_DIM
      hints=(
        "[t] change   [p] permanent   [x] manage   [o] mini"
        "[s] stop   [q] quit · keep   [Q] quit · stop"
      )
      ;;
    permanent)
      mc=$COL_AMBER
      header="∞  permanent · staying awake"
      linea=$(moka_space_out "$(moka_fmt_hms "$(moka_elapsed "${MOKA_START:-$now}" "$now")")")
      ca="$C_BOLD$mc"
      lineb="elapsed · pid ${MOKA_PID:-?}" cb=$C_DIM
      hints=(
        "[t] timed   [x] manage   [o] mini"
        "[s] stop   [q] quit · keep   [Q] quit · stop"
      )
      ;;
  esac

  MOKA_OUT=$'\e[2J'

  # Status line (transient expiry banner wins; else unmanaged warning).
  if [[ -n "${banner:-}" ]] && ((now < ${banner_until:-0})); then
    moka_banner "$top" "$C_BOLD$COL_AMBER" "$banner"
  else
    local -a ulist
    mapfile -t ulist < <(moka_unmanaged_list)
    if ((${#ulist[@]} > 0)); then
      local u0=${ulist[0]} udir prefix suffix avail umsg
      udir=$(moka_abbrev_home "$(moka_proc_cwd "$u0")")
      prefix="⚠ unmanaged · pid $u0 · "
      suffix=""
      ((${#ulist[@]} > 1)) && suffix=" · +$((${#ulist[@]} - 1)) more"
      avail=$((MOKA_COLS - ${#prefix} - ${#suffix}))
      ((avail < 8)) && avail=8
      umsg="${prefix}$(moka_trunc_tail "$udir" "$avail")${suffix}"
      ((${#umsg} > MOKA_COLS)) && umsg="${umsg:0:MOKA_COLS}"
      moka_banner "$top" "$C_DIM$COL_AMBER" "$umsg"
    fi
  fi

  # Box.
  local r=$((top + 1))
  moka_move "$r" "$left"
  moka_app '%s╭%s╮%s' "$mc" "$MOKA_DASH" "$C_RESET"
  moka_box_line $((r + 1)) "$left" "$mc" "$C_BOLD$mc" "$(moka_center_in "$MOKA_INNER" "$header")"
  moka_move $((r + 2)) "$left"
  moka_app '%s├%s┤%s' "$mc" "$MOKA_DASH" "$C_RESET"
  moka_box_line $((r + 3)) "$left" "$mc" "" "$(moka_center_in "$MOKA_INNER" "")"
  moka_box_line $((r + 4)) "$left" "$mc" "$ca" "$(moka_center_in "$MOKA_INNER" "$linea")"
  moka_box_line $((r + 5)) "$left" "$mc" "$cb" "$(moka_center_in "$MOKA_INNER" "$lineb")"
  moka_box_line $((r + 6)) "$left" "$mc" "" "$(moka_center_in "$MOKA_INNER" "")"
  moka_move $((r + 7)) "$left"
  moka_app '%s╰%s╯%s' "$mc" "$MOKA_DASH" "$C_RESET"

  # Hints.
  local hr=$((top + 10)) h
  for h in "${hints[@]}"; do
    moka_hint "$hr" "$h"
    hr=$((hr + 1))
  done

  printf '%s' "$MOKA_OUT"
}

# Manage screen: full-width list of unmanaged caffeinate — pid, timer, directory.
moka_draw_manage() { # now
  # Use most of the pane width so long directories are visible.
  local inner=$((MOKA_COLS - 4))
  ((inner < 40)) && inner=40
  local box_w=$((inner + 2))
  local left=$(((MOKA_COLS - box_w) / 2))
  ((left < 0)) && left=0
  local dash
  dash=$(moka_dashes "$inner")
  local n=${#MOKA_MANAGE_PIDS[@]}
  local listrows=$n
  ((listrows == 0)) && listrows=1
  local top=$(((MOKA_LINES - (listrows + 6)) / 2))
  ((top < 0)) && top=0
  local mc=$COL_AMBER

  MOKA_OUT=$'\e[2J'
  local r=$top
  moka_move "$r" "$left"
  moka_app '%s╭%s╮%s' "$mc" "$dash" "$C_RESET"
  moka_box_line $((r + 1)) "$left" "$mc" "$C_BOLD$mc" "$(moka_center_in "$inner" "⚠  unmanaged caffeinate")"
  moka_move $((r + 2)) "$left"
  moka_app '%s├%s┤%s' "$mc" "$dash" "$C_RESET"

  local row=$((r + 3)) i pid dir timer marker cc content
  if ((n == 0)); then
    moka_box_line "$row" "$left" "$mc" "$C_DIM" "$(moka_center_in "$inner" "no unmanaged caffeinate")"
    row=$((row + 1))
  else
    for ((i = 0; i < n; i++)); do
      pid=${MOKA_MANAGE_PIDS[i]}
      dir=$(moka_abbrev_home "$(moka_proc_cwd "$pid")")
      timer=$(moka_proc_timer "$pid")
      if ((i == manage_sel)); then
        marker="▸" cc="$C_BOLD"
      else
        marker=" " cc="$C_DIM"
      fi
      content="  ${marker}[$((i + 1))] $(moka_pad_right "$pid" 6) $(moka_pad_right "$timer" 11) ${dir}"
      moka_box_line "$row" "$left" "$mc" "$cc" "$(moka_ljust_in "$inner" "$content")"
      row=$((row + 1))
    done
  fi

  moka_move "$row" "$left"
  moka_app '%s╰%s╯%s' "$mc" "$dash" "$C_RESET"
  if ((n == 0)); then
    moka_hint $((row + 2)) "[esc] back"
  elif [[ "$screen" == manage_confirm ]]; then
    local cpid=${MOKA_MANAGE_PIDS[manage_sel]}
    moka_banner $((row + 2)) "$C_BOLD$COL_RED" "terminate pid $cpid?"
    moka_hint $((row + 3)) "[y] yes   [any other key] cancel"
  else
    moka_hint $((row + 2)) "[j/k] move   [x] terminate   [o] mini   [esc] back"
  fi
  printf '%s' "$MOKA_OUT"
}

# Compact single-line view for tiny panes: [warn] state • keymaps
moka_draw_oneline() { # now
  local now=$1 mc warn_c="" warn_p="" state="" keys=""
  local -a ulist
  mapfile -t ulist < <(moka_unmanaged_list)
  if ((${#ulist[@]} > 0)); then
    warn_c="${COL_AMBER}⚠${C_RESET} "
    warn_p="⚠ "
  fi
  case "$screen" in
    idle)
      mc=$COL_SLATE
      state="idle"
      keys="[p]erm [t]imed [x]mng [o]full [q]uit"
      ;;
    setup)
      mc=$COL_TEAL
      state="set $(moka_fmt_hms "$buf")"
      keys="[h/m/i]± [↵]start [esc]cancel"
      ;;
    timed)
      local rem
      rem=$(moka_remaining "${MOKA_END:-0}" "$now")
      if ((rem < 60)); then mc=$COL_RED; elif ((rem < 300)); then mc=$COL_ORANGE; else mc=$COL_TEAL; fi
      state="⏱ $(moka_fmt_hms "$rem") #${MOKA_PID:-?}"
      keys="[t]ime [p]erm [s]top [q]keep [Q]stop"
      ;;
    permanent)
      # Neutral (not amber) so the ⚠ glyph is the only yellow thing in mini mode.
      mc=$C_BOLD
      state="∞ $(moka_fmt_hms "$(moka_elapsed "${MOKA_START:-$now}" "$now")") #${MOKA_PID:-?}"
      keys="[t]imed [s]top [q]keep [Q]stop"
      ;;
    manage | manage_confirm)
      mc=$COL_AMBER
      local n=${#MOKA_MANAGE_PIDS[@]}
      if ((n == 0)); then
        state="manage: none"
        keys="[o]full [esc]back"
      elif [[ "$screen" == manage_confirm ]]; then
        local sp=${MOKA_MANAGE_PIDS[manage_sel]}
        mc=$COL_RED
        state="kill #$sp?"
        keys="[y]es [any]cancel"
      else
        local sp=${MOKA_MANAGE_PIDS[manage_sel]}
        state="manage $((manage_sel + 1))/$n #$sp $(moka_abbrev_home "$(moka_proc_cwd "$sp")")"
        keys="[j/k] [x]kill [esc]back"
      fi
      ;;
  esac
  if [[ -n "${banner:-}" ]] && ((now < ${banner_until:-0})); then
    mc=$COL_AMBER
    state="$banner"
  fi

  local colored="${warn_c}${mc}${state}${C_RESET} ${C_DIM}•${C_RESET} $(moka_colorize_keys "$keys")"
  local plain="${warn_p}${state} • ${keys}"
  local orow=$(((MOKA_LINES - 1) / 2))
  ((orow < 0)) && orow=0

  MOKA_OUT=$'\e[2J'
  moka_move "$orow" 0
  if ((${#plain} <= MOKA_COLS)); then
    moka_app '%s' "$colored"
  else
    moka_app '%s' "${plain:0:MOKA_COLS}"
  fi
  printf '%s' "$MOKA_OUT"
}

# ---------------------------------------------------------------------------
# Input & main loop
# ---------------------------------------------------------------------------

# If the last key was ESC, drain any follow-on bytes so arrow keys and other
# escape sequences don't read as a bare ESC (cancel).
moka_maybe_drain_esc() {
  [[ "$key" == $'\e' ]] || return 0
  ((BASH_VERSINFO[0] >= 4)) || return 0
  local rest
  if IFS= read -rsn8 -t 0.01 rest 2>/dev/null && [[ -n "$rest" ]]; then
    case "$rest" in
      '[A' | 'OA') key="__up__" ;;
      '[B' | 'OB') key="__down__" ;;
      *) key="__seq__" ;;
    esac
  fi
}

# Re-sync from the shared state file so every moka window reflects the single
# global session, adopts it, and excludes its pid from "unmanaged".
moka_sync_session() { # now
  local now=$1 alive=0 mode="" expired=0
  if moka_state_read && moka_pid_is_caffeinate "${MOKA_PID:-}"; then
    if [[ "$MOKA_MODE" == timed ]] && (($(moka_remaining "${MOKA_END:-0}" "$now") <= 0)); then
      expired=1
    else
      alive=1 mode=$MOKA_MODE
    fi
  fi
  if ((alive)); then
    screen=$(moka_reconcile_screen 1 "$mode" "$screen")
  else
    if ((expired)) && [[ "$screen" == timed ]]; then
      banner="⏰ timer expired" banner_until=$((now + 3))
    fi
    moka_state_clear
    MOKA_MODE="" MOKA_PID="" MOKA_START="" MOKA_END=""
    screen=$(moka_reconcile_screen 0 "" "$screen")
  fi
}

# Handle an action. Returns 1 to exit the loop.
moka_dispatch() {
  case "$1" in
    none) ;;
    quit | quit_keep) return 1 ;;
    quit_stop) moka_stop_process; return 1 ;;
    stop) moka_stop_process; screen=idle ;;
    start_permanent | switch_permanent) moka_start_permanent; screen=permanent ;;
    goto_setup)
      if [[ "$screen" == timed ]]; then
        buf=$(moka_remaining "${MOKA_END:-0}" "$(moka_now)")
        ((buf < MOKA_MIN_SECONDS)) && buf=$MOKA_MIN_SECONDS
      else
        buf=$MOKA_DEFAULT_BUFFER
      fi
      setup_return=$screen
      screen=setup
      ;;
    add_h) buf=$(moka_buffer_adjust "$buf" 3600) ;;
    sub_h) buf=$(moka_buffer_adjust "$buf" -3600) ;;
    add_m) buf=$(moka_buffer_adjust "$buf" 1800) ;;
    sub_m) buf=$(moka_buffer_adjust "$buf" -1800) ;;
    add_i) buf=$(moka_buffer_adjust "$buf" 60) ;;
    sub_i) buf=$(moka_buffer_adjust "$buf" -60) ;;
    commit) moka_start_timed "$buf"; screen=timed ;;
    cancel)
      screen=${setup_return:-idle}
      if [[ "$screen" == timed ]] && ! moka_pid_is_caffeinate "${MOKA_PID:-}"; then
        moka_state_clear
        MOKA_MODE="" MOKA_PID="" MOKA_START="" MOKA_END=""
        screen=idle
      fi
      ;;
    goto_manage) manage_return=$screen; manage_sel=0; screen=manage ;;
    move_down) manage_sel=$((manage_sel + 1)) ;;
    move_up) manage_sel=$((manage_sel - 1)) ;;
    ask_terminate)
      local mn=${#MOKA_MANAGE_PIDS[@]}
      ((mn > 0)) && ((manage_sel < mn)) && screen=manage_confirm
      ;;
    confirm_terminate)
      local mn=${#MOKA_MANAGE_PIDS[@]}
      if ((mn > 0)) && ((manage_sel < mn)); then
        kill "${MOKA_MANAGE_PIDS[manage_sel]}" 2>/dev/null || true
      fi
      screen=manage
      ;;
    cancel_terminate) screen=manage ;;
    back) screen=$manage_return ;;
    toggle_oneline) oneline=$((1 - oneline)) ;;
  esac
  return 0
}

moka_init_state() {
  screen=idle
  buf=$MOKA_DEFAULT_BUFFER
  setup_return=idle
  manage_return=idle
  manage_sel=0
  MOKA_MANAGE_PIDS=()
  oneline=0
  banner=""
  banner_until=0
  if moka_state_read && moka_pid_is_caffeinate "${MOKA_PID:-}"; then
    screen=$MOKA_MODE
  else
    moka_state_clear
    MOKA_MODE="" MOKA_PID="" MOKA_START="" MOKA_END=""
  fi
}

moka_teardown() {
  tput cnorm 2>/dev/null || true
  tput rmcup 2>/dev/null || true
}

moka_loop() {
  trap moka_teardown EXIT INT TERM
  tput smcup 2>/dev/null || true
  tput civis 2>/dev/null || true
  local key had_key rc action now
  while true; do
    now=$(moka_now)
    # Re-sync the shared session each tick so every window agrees and the
    # managed pid is excluded from "unmanaged" (fixes cross-window flagging).
    moka_sync_session "$now"

    # Keep the manage list (and selection) fresh so draw + dispatch agree.
    if [[ "$screen" == manage ]]; then
      mapfile -t MOKA_MANAGE_PIDS < <(moka_unmanaged_list)
      local mn=${#MOKA_MANAGE_PIDS[@]}
      ((manage_sel < 0)) && manage_sel=0
      if ((mn == 0)); then
        manage_sel=0
      elif ((manage_sel >= mn)); then
        manage_sel=$((mn - 1))
      fi
    fi

    moka_draw "$now"

    key="" had_key=0
    if IFS= read -rsn1 -t 1 key; then
      had_key=1
      moka_maybe_drain_esc
    else
      rc=$?
      ((rc <= 128)) && break  # EOF/error (not a timeout)
    fi
    ((had_key)) || continue
    action=$(moka_key_to_action "$screen" "$key")
    moka_dispatch "$action" || break
  done
}

moka_main() {
  if [[ "${1:-}" == status ]]; then
    shift
    moka_status_cmd "$@"
    return $?
  fi
  if ! command -v "$MOKA_CAFFEINATE" >/dev/null 2>&1; then
    printf 'moka: %s not found — this tool is macOS-only.\n' "$MOKA_CAFFEINATE" >&2
    return 1
  fi
  moka_setup_colors
  MOKA_DASH=""
  local i
  for ((i = 0; i < MOKA_INNER; i++)); do MOKA_DASH+="─"; done
  moka_init_state
  moka_loop
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  moka_main "$@"
fi
