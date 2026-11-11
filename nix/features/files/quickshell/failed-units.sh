#!/usr/bin/env bash
for scope in system user; do
  echo "$scope units"
  args=()
  [[ $scope == user ]] && args+=(--user)
  systemctl "${args[@]}" --failed --no-pager
  while read -r unit _; do
    [[ -n $unit ]] || continue
    systemctl "${args[@]}" status "$unit" --no-pager || true
    journalctl "${args[@]}" -b -u "$unit" -n 50 --no-pager
  done < <(systemctl "${args[@]}" --failed --no-legend --plain)
done
read -r -p 'Press Enter to close...' _
