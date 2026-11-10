# Exercise the real policy with fake sysfs and a fake daemon, never host power state.
policy="$1"
export XDG_RUNTIME_DIR="$PWD/runtime"
export POWER_PROFILE_SUPPLIES="$PWD/supplies"
export MOCK_PROFILE="$PWD/profile"
export MOCK_WRITES="$PWD/writes"
mkdir -p bin "$XDG_RUNTIME_DIR" "$POWER_PROFILE_SUPPLIES/AC" "$POWER_PROFILE_SUPPLIES/BAT0"
printf Mains > "$POWER_PROFILE_SUPPLIES/AC/type"
printf Battery > "$POWER_PROFILE_SUPPLIES/BAT0/type"
printf 0 > "$POWER_PROFILE_SUPPLIES/AC/online"
printf 75 > "$POWER_PROFILE_SUPPLIES/BAT0/capacity"
printf balanced > "$MOCK_PROFILE"
: > "$MOCK_WRITES"
printf '#!%s\n' "$(command -v bash)" > bin/powerprofilesctl
cat >> bin/powerprofilesctl <<'MOCK'
set -euo pipefail
case "$1" in
  get) cat "$MOCK_PROFILE" ;;
  set)
    [[ "${MOCK_FAIL:-0}" == 0 ]] || exit 1
    printf '%s' "$2" > "$MOCK_PROFILE"
    echo "$2" >> "$MOCK_WRITES"
    ;;
esac
MOCK
chmod +x bin/powerprofilesctl
export PATH="$PWD/bin:$PATH"
run() { bash -euo pipefail "$policy" "$@"; }
expect() { [[ "$(cat "$MOCK_PROFILE")" == "$1" ]]; }

# Automatic policy and exact threshold, without redundant writes.
run auto
expect balanced
[[ ! -s "$MOCK_WRITES" ]]
printf 40 > "$POWER_PROFILE_SUPPLIES/BAT0/capacity"
run apply
expect power-saver
printf 41 > "$POWER_PROFILE_SUPPLIES/BAT0/capacity"
run apply
expect balanced
printf 1 > "$POWER_PROFILE_SUPPLIES/AC/online"
run apply
expect performance

# A manual selection survives ticks and AC/battery changes.
run balanced
printf 10 > "$POWER_PROFILE_SUPPLIES/BAT0/capacity"
printf 0 > "$POWER_PROFILE_SUPPLIES/AC/online"
run apply
expect balanced
run status | jq -e '.class == ["manual", "balanced"] and (.tooltip | startswith("Manual · Balanced"))'

# The login command and Automatic menu action both clear the override immediately.
run auto
expect power-saver
run status | jq -e '.class == ["auto", "power-saver"]'
run performance
run auto
expect power-saver

# A failed manual change must not disable Auto or claim a successful profile.
if MOCK_FAIL=1 run performance; then
  echo 'Expected a failed profile change' >&2
  exit 1
fi
[[ ! -e "$XDG_RUNTIME_DIR/power-profile-policy/manual" ]]
expect power-saver

# Missing battery data has a safe fallback, rather than failing every timer tick.
rm "$POWER_PROFILE_SUPPLIES/BAT0/capacity"
run auto
expect balanced
echo 'PASS: automatic thresholds, manual override, login reset, tooltip and failure handling'
