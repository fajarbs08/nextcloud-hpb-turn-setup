#!/bin/bash

set -euo pipefail

OUTPUT="/var/www/html/hpb-status.json"
SERVICES_FILE="/etc/hpb-status/services.conf"
HOSTNAME_VALUE="$(hostname -f 2>/dev/null || hostname)"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

service_unit() {
	local svc="$1"
	case "$svc" in
		signaling) echo "nextcloud-spreed-signaling" ;;
		nats) echo "nats-server" ;;
		*) echo "$svc" ;;
	esac
}

status_of() {
	local svc="$1"
	local unit
	unit="$(service_unit "$svc")"
	local state=""
	state="$(systemctl is-active "$unit" 2>/dev/null || true)"
	if [ -z "$state" ]; then
		state="not-found"
	fi
	echo "$state"
}

read_services() {
	local services=()
	if [ -s "$SERVICES_FILE" ]; then
		while IFS= read -r line; do
			line="${line%%#*}"
			line="$(echo "$line" | xargs || true)"
			[ -z "$line" ] && continue
			services+=("$line")
		done <"$SERVICES_FILE"
	else
		services=("nginx")
	fi
	echo "${services[@]}"
}

umask 022
mkdir -p "$(dirname "$OUTPUT")"

services_list=($(read_services))

cat >"$OUTPUT" <<EOF
{
  "generated_at": "$TIMESTAMP",
  "host": "$HOSTNAME_VALUE",
  "services": {
EOF

first=1
for svc in "${services_list[@]}"; do
	if [ $first -eq 0 ]; then
		echo "," >>"$OUTPUT"
	fi
	first=0
	printf '    "%s": "%s"' "$svc" "$(status_of "$svc")" >>"$OUTPUT"
done

cat >>"$OUTPUT" <<EOF
  }
}
EOF

chmod 0644 "$OUTPUT"
