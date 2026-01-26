#!/bin/bash

function install_nginx() {
	announce_installation "Installing Nginx"
	log "Installing Nginx…"

	nginx_step1
	nginx_step2
	nginx_step3
	nginx_tune_global

	log "Nginx install completed."
}

function nginx_step1() {
	log "\n${green}Step 1: Installing Nginx package"
	if ! is_dry_run; then
		if [ "$UNATTENDED_INSTALL" == true ]; then
			log "Trying unattended install for Nginx."
			export DEBIAN_FRONTEND=noninteractive
			apt-get install -qqy nginx ssl-cert 2>&1 | tee -a $LOGFILE_PATH
		else
			apt-get install -y nginx ssl-cert 2>&1 | tee -a $LOGFILE_PATH
		fi
	fi
}

function nginx_step2() {
	log "\n${green}Step 2: Prepare configuration"

	generate_dhparam_file

	include_snippet_signaling_forwarding=""
	include_snippet_signaling_upstream_servers=""
	if [ "$SHOULD_INSTALL_SIGNALING" == true ]; then
		include_snippet_signaling_forwarding="# Signaling\n  include snippets/signaling-forwarding.conf;\n"
		include_snippet_signaling_upstream_servers="include snippets/signaling-upstream-servers.conf;\n"
		log "Replacing '<INCLUDE_SNIPPET_SIGNALING_FORWARDING>' with '$include_snippet_signaling_forwarding'…"
		log "Replacing '<INCLUDE_SNIPPET_SIGNALING_UPSTREAM_SERVERS>' with '$include_snippet_signaling_upstream_servers'…"
	fi
	sed -i "s|<INCLUDE_SNIPPET_SIGNALING_FORWARDING>|$include_snippet_signaling_forwarding|g" "$TMP_DIR_PATH"/nginx/nextcloud-hpb.conf
	sed -i "s|<INCLUDE_SNIPPET_SIGNALING_UPSTREAM_SERVERS>|$include_snippet_signaling_upstream_servers|g" "$TMP_DIR_PATH"/nginx/nextcloud-hpb.conf

	include_snippet_collabora=""
	if [ "$SHOULD_INSTALL_COLLABORA" == true ]; then
		include_snippet_collabora="# Collabora\n  include snippets/coolwsd.conf;"
		log "Replacing '<INCLUDE_SNIPPET_COLLABORA>' with '$include_snippet_collabora'…"
	fi
	sed -i "s|<INCLUDE_SNIPPET_COLLABORA>|$include_snippet_collabora|g" "$TMP_DIR_PATH"/nginx/nextcloud-hpb.conf

	include_snippet_realip=""
	if [ "$USE_CLOUDFLARE_PROXY" == true ]; then
		include_snippet_realip="include /etc/nginx/snippets/realip-cloudflare.conf;"
		log "Cloudflare proxy enabled; real IP snippet will be included."
	fi
	sed -i "s|<INCLUDE_SNIPPET_REALIP_CLOUDFLARE>|$include_snippet_realip|g" "$TMP_DIR_PATH"/nginx/nextcloud-hpb.conf

	if [ "$DNS_RESOLVER" = "" ]; then
		DNS_RESOLVER="9.9.9.9"
		log "Using default value '$DNS_RESOLVER' for DNS_RESOLVER".
	else
		log "Using '$DNS_RESOLVER' for DNS_RESOLVER".
	fi

	log "Replacing '<SERVER_FQDN>' with '$SERVER_FQDN'…"
	sed -i "s|<SERVER_FQDN>|$SERVER_FQDN|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<SSL_CERT_PATH_RSA>' with '$SSL_CERT_PATH_RSA'…"
	sed -i "s|<SSL_CERT_PATH_RSA>|$SSL_CERT_PATH_RSA|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<SSL_CERT_KEY_PATH_RSA>' with '$SSL_CERT_KEY_PATH_RSA'…"
	sed -i "s|<SSL_CERT_KEY_PATH_RSA>|$SSL_CERT_KEY_PATH_RSA|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<SSL_CHAIN_PATH_RSA>' with '$SSL_CHAIN_PATH_RSA'…"
	sed -i "s|<SSL_CHAIN_PATH_RSA>|$SSL_CHAIN_PATH_RSA|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<SSL_CERT_PATH_ECDSA>' with '$SSL_CERT_PATH_ECDSA'…"
	sed -i "s|<SSL_CERT_PATH_ECDSA>|$SSL_CERT_PATH_ECDSA|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<SSL_CERT_KEY_PATH_ECDSA>' with '$SSL_CERT_KEY_PATH_ECDSA'…"
	sed -i "s|<SSL_CERT_KEY_PATH_ECDSA>|$SSL_CERT_KEY_PATH_ECDSA|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<SSL_CHAIN_PATH_ECDSA>' with '$SSL_CHAIN_PATH_ECDSA'…"
	sed -i "s|<SSL_CHAIN_PATH_ECDSA>|$SSL_CHAIN_PATH_ECDSA|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<DHPARAM_PATH>' with '$DHPARAM_PATH'…"
	sed -i "s|<DHPARAM_PATH>|$DHPARAM_PATH|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<DNS_RESOLVER>' with '$DNS_RESOLVER'…"
	sed -i "s|<DNS_RESOLVER>|$DNS_RESOLVER|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<DEBIAN_VERSION>' with '$DEBIAN_VERSION_MAJOR'…"
	sed -i "s|<DEBIAN_VERSION>|$DEBIAN_VERSION_MAJOR|g" "$TMP_DIR_PATH"/nginx/*

	log "Replacing '<SCRIPT_VERSION>' with '$SETUP_VERSION'…"
	sed -i "s|<SCRIPT_VERSION>|$SETUP_VERSION|g" "$TMP_DIR_PATH"/nginx/*

	# Build allowlist for /hpb-status.json
	allow_block=""
	if [ -n "$HPB_STATUS_ALLOWED_IPS" ]; then
		IFS=',' read -ra _ips <<<"$HPB_STATUS_ALLOWED_IPS"
		for _ip in "${_ips[@]}"; do
			_ip="$(echo "$_ip" | xargs || true)"
			[ -z "$_ip" ] && continue
			allow_block+=$'    allow '"${_ip}"$';\n'
		done
		allow_block+=$'    deny all;\n'
	else
		allow_block=$'    allow all;\n'
	fi
	if ! is_dry_run; then
		NGINX_CONF_PATH="$TMP_DIR_PATH/nginx/nextcloud-hpb.conf" ALLOW_BLOCK="$allow_block" python3 - <<'PY'
import os
path = os.environ["NGINX_CONF_PATH"]
block = os.environ["ALLOW_BLOCK"]
with open(path, "r", encoding="utf-8") as f:
    data = f.read()
data = data.replace("<HPB_STATUS_ALLOW_BLOCK>", block)
with open(path, "w", encoding="utf-8") as f:
    f.write(data)
PY
	else
		log "Would replace '<HPB_STATUS_ALLOW_BLOCK>' in nginx config."
	fi
}

function nginx_step3() {
	log "Deploying config files…"
	deploy_file "$TMP_DIR_PATH"/nginx/nextcloud-hpb.conf /etc/nginx/sites-enabled/nextcloud-hpb.conf || true

	is_dry_run || mkdir -p /etc/nginx/snippets || true
	deploy_file "$TMP_DIR_PATH"/nginx/headers.conf /etc/nginx/snippets/headers.conf || true
	if [ "$USE_CLOUDFLARE_PROXY" == true ]; then
		deploy_file "$TMP_DIR_PATH"/nginx/realip-cloudflare.conf /etc/nginx/snippets/realip-cloudflare.conf || true
	fi

	is_dry_run || mkdir -p /etc/nginx/conf.d || true
	deploy_file "$TMP_DIR_PATH"/nginx/nextcloud-hpb-tuning.conf /etc/nginx/conf.d/nextcloud-hpb-tuning.conf || true
	deploy_file "$TMP_DIR_PATH"/nginx/nextcloud-hpb-rate-limit.conf /etc/nginx/conf.d/nextcloud-hpb-rate-limit.conf || true

	is_dry_run || mkdir -p /var/www/html || true
	is_dry_run || rm /var/www/html/index.nginx-debian.html || true
	deploy_file "$TMP_DIR_PATH"/nginx/index.html /var/www/html/index.html || true
	deploy_file "$TMP_DIR_PATH"/nginx/robots.txt /var/www/html/robots.txt || true

	is_dry_run || mkdir -p /usr/local/bin || true
	deploy_file "$TMP_DIR_PATH"/hpb-status/hpb-status.sh /usr/local/bin/hpb-status || true
	is_dry_run || chmod 0755 /usr/local/bin/hpb-status
	deploy_file "$TMP_DIR_PATH"/hpb-status/hpb-status.service /etc/systemd/system/hpb-status.service || true
	deploy_file "$TMP_DIR_PATH"/hpb-status/hpb-status.timer /etc/systemd/system/hpb-status.timer || true
	if ! is_dry_run; then
		mkdir -p /etc/hpb-status
		{
			echo "nginx"
			if [ "$SHOULD_INSTALL_SIGNALING" = true ]; then
				echo "signaling"
				echo "janus"
				echo "nats"
			fi
			if [ "$SHOULD_INSTALL_COTURN" = true ]; then
				echo "coturn"
			fi
		} >/etc/hpb-status/services.conf
		chmod 0644 /etc/hpb-status/services.conf
	fi
	if ! is_dry_run; then
		systemctl daemon-reload | tee -a $LOGFILE_PATH
		systemctl enable --now hpb-status.timer 2>&1 | tee -a $LOGFILE_PATH
	fi
}

function nginx_tune_global() {
	log "\n${green}Step 4: Global Nginx tuning (moderate spec)"
	local nginx_conf="/etc/nginx/nginx.conf"
	local worker_connections="4096"

	if is_dry_run; then
		log "Would tune global Nginx settings in '$nginx_conf'."
		return 0
	fi

	if [ ! -f "$nginx_conf" ]; then
		log_err "Nginx config not found at '$nginx_conf'. Skipping global tuning."
		return 0
	fi

	python3 - <<'PY'
import re
from pathlib import Path

nginx_conf = Path("/etc/nginx/nginx.conf")
data = nginx_conf.read_text()
lines = data.splitlines()

worker_connections = "4096"
seen_wp = False
seen_wc = False
seen_use = False
seen_multi = False
seen_events = False
in_events = False

out = []
for line in lines:
    if re.match(r"^\s*worker_processes\b", line):
        out.append("worker_processes auto;")
        seen_wp = True
        continue

    if re.match(r"^\s*events\s*\{", line):
        in_events = True
        seen_events = True
        out.append(line)
        continue

    if in_events:
        if re.match(r"^\s*worker_connections\b", line):
            out.append("    worker_connections %s;" % worker_connections)
            seen_wc = True
            continue
        if re.match(r"^\s*use\s+epoll;", line):
            seen_use = True
        if re.match(r"^\s*multi_accept\s+on;", line):
            seen_multi = True
        if re.match(r"^\s*\}", line):
            if not seen_wc:
                out.append("    worker_connections %s;" % worker_connections)
            if not seen_use:
                out.append("    use epoll;")
            if not seen_multi:
                out.append("    multi_accept on;")
            out.append(line)
            in_events = False
            continue

    out.append(line)

if not seen_wp:
    # Insert after 'user' directive if present, otherwise prepend.
    inserted = False
    for idx, line in enumerate(out):
        if re.match(r"^\s*user\b", line):
            out.insert(idx + 1, "worker_processes auto;")
            inserted = True
            break
    if not inserted:
        out.insert(0, "worker_processes auto;")

if not seen_events:
    out.append("")
    out.append("events {")
    out.append("    worker_connections %s;" % worker_connections)
    out.append("    use epoll;")
    out.append("    multi_accept on;")
    out.append("}")

nginx_conf.write_text("\n".join(out) + "\n")
PY
}

# arg: $1 is secret file path
function nginx_write_secrets_to_file() {
	# No secrets, passwords, keys or something to worry about.
	if is_dry_run; then
		return 0
	fi
}

function nginx_print_info() {
	log "Nginx got installed which acts as a reverse proxy for your selected" \
		"\nservices. No extra configuration needed."

	if [ "$SHOULD_INSTALL_CERTBOT" != true ]; then
		log "\nExcept one thing. Since you choose to not install an automatic" \
			"\nSSL-Certificate renewer (certbot for example), you need to make" \
			"\nsure that at all time a valid SSL-Cert is located at: " \
			"\n'$SSL_CERT_PATH_RSA' and '$SSL_CERT_KEY_PATH_RSA' (for RSA certificates)" \
			"\n'$SSL_CERT_PATH_ECDSA' and '$SSL_CERT_KEY_PATH_ECDSA' (for ECDSA certificates)."
	fi
}
