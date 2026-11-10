# One lock serializes menu actions, automatic updates and status reads.
state_dir="${XDG_RUNTIME_DIR:?}/power-profile-policy"
mkdir -p "$state_dir"
exec 9>"$state_dir/lock"
flock 9
supplies="${POWER_PROFILE_SUPPLIES:-/sys/class/power_supply}"

choose_profile() {
  local supply capacity="" on_ac=0
  for supply in "$supplies"/*; do
    [[ -r "$supply/type" ]] || continue
    case "$(cat "$supply/type")" in
      Mains|USB|USB_C|USB_PD)
        if [[ -r "$supply/online" && "$(cat "$supply/online")" == 1 ]]; then
          on_ac=1
        fi
        ;;
      Battery)
        if [[ -r "$supply/capacity" && -z "$capacity" ]]; then
          capacity="$(cat "$supply/capacity")"
        fi
        ;;
    esac
  done
  if (( on_ac )); then
    echo performance
  elif [[ "$capacity" =~ ^[0-9]+$ ]] && (( capacity <= 40 )); then
    echo power-saver
  else
    # Safe default for machines without a readable battery.
    echo balanced
  fi
}

apply_profile() {
  local profile="$1"
  # Avoid redundant D-Bus writes on every timer tick.
  if [[ "$(powerprofilesctl get)" != "$profile" ]]; then
    powerprofilesctl set "$profile"
  fi
}

case "${1:-status}" in
  auto)
    # Login and the Automatic menu item both explicitly resume automation.
    rm -f "$state_dir/manual"
    apply_profile "$(choose_profile)"
    ;;
  apply)
    [[ -f "$state_dir/manual" ]] || apply_profile "$(choose_profile)"
    ;;
  power-saver|balanced|performance)
    # Commit manual mode only after a successful profile change.
    apply_profile "$1"
    touch "$state_dir/manual"
    ;;
  status)
    mode=Auto
    [[ ! -f "$state_dir/manual" ]] || mode=Manual
    profile="$(powerprofilesctl get)" || profile=unavailable
    case "$profile" in
      power-saver) icon=''; label='Power Saver' ;;
      balanced) icon=''; label=Balanced ;;
      performance) icon=''; label=Performance ;;
      *) icon='?'; label=Unavailable ;;
    esac
    jq -cn --arg text "$icon" --arg mode "$mode" --arg label "$label" \
      --arg profile "$profile" \
      '{text: $text, tooltip: ($mode + " · " + $label + "\nClick to choose Automatic or a manual profile"), class: [($mode | ascii_downcase), $profile]}'
    ;;
  *) echo "Usage: power-profile-policy {auto|apply|power-saver|balanced|performance|status}" >&2; exit 2 ;;
esac
