# !!! Be careful, this script will be executed by the root user. !!!

# Please have a look at this Wiki page for this file:
# NOTE: It's in german.
# https://github.com/sunweaver/nextcloud-high-performance-backend-setup/wiki/02-Setup-Script

# Dry run (Don't actually alter anything on the system. (except in $TMP_DIR_PATH))
# Leave empty, if you wish that the user will be asked about this.
DRY_RUN=false

# Should the script try to install the high-performance-backend server
# without any user input?
UNATTENDED_INSTALL=false

# General settings
# Leave empty, if you wish that the user will be asked about this.
# You can also specify multiple Nextcloud servers by separating them with commas.
#NEXTCLOUD_SERVER_FQDNS="nextcloud.example.org"
# Leave empty, if you wish that the user will be asked about this.
#SERVER_FQDN="nc-workhorse.example.org"
# If Coturn berada di host berbeda, setel domainnya di sini.
#SIGNALING_COTURN_URL="turn.example.org"
# Reuse this secret if Coturn and HPB run on different hosts.
#SIGNALING_TURN_STATIC_AUTH_SECRET=""
#SIGNALING_COTURN_TLS_PORT="5349"

# Only modify if you know what you're doing.
#SSL_CERT_PATH_RSA=""
#SSL_CERT_KEY_PATH_RSA=""
#SSL_CHAIN_PATH_RSA=""
#SSL_CERT_PATH_ECDSA=""
#SSL_CERT_KEY_PATH_ECDSA=""
#SSL_CHAIN_PATH_ECDSA=""
#DHPARAM_PATH=""

# Collabora (Gets asked anyway, except unattended install.)
SHOULD_INSTALL_COLLABORA=false

# Signaling (Gets asked anyway, except unattended install.)
SHOULD_INSTALL_SIGNALING=false
SHOULD_INSTALL_COTURN=false

SHOULD_INSTALL_UFW=false
SHOULD_INSTALL_NGINX=false
SHOULD_INSTALL_CERTBOT=false
SHOULD_INSTALL_UNATTENDEDUPGRADES=false

# Logfile get created if UNATTENDED_INSTALL is true.
# Leave empty, if you wish that the user will be asked about this.
LOGFILE_PATH="$(pwd)/setup-nextcloud-hpb-$(date +%Y-%m-%dT%H:%M:%SZ).log"

# Configuration gets copied and prepared here before copying them into place.
# This prevents config being broken if something goes wrong.
# Leave empty, if you wish that the user will be asked about this.
TMP_DIR_PATH="./tmp"

# Secrets, passwords and configuration gets saved in this file.
# Leave empty, if you wish that the user will be asked about this.
SECRETS_FILE_PATH="/opt/fajarlabs/nextcloud-hpb.secrets"

# Optional email address for Certbot registration (no SMTP setup).
EMAIL_USER_ADDRESS=""

# Should the ssh service be disabled?
#DISABLE_SSH_SERVER=false

# Should nextcloud-spreed-signaling, nats-server and coturn be built and
# installed from sources?
SIGNALING_BUILD_FROM_SOURCES=""

# DNS Resolver. Here a custom DNS server can be specified,
# otherwise the one configured in resolv.conf is used
DNS_RESOLVER=""

# Set to true if Nginx is behind Cloudflare proxy (orange cloud).
USE_CLOUDFLARE_PROXY=false

# Allowed IPs for /hpb-status.json (comma-separated). Leave empty to allow all.
HPB_STATUS_ALLOWED_IPS="15.235.236.121/32,51.254.136.125/32,51.79.236.3/32,51.79.236.4/32,51.79.236.5/32,51.79.236.6/32"

# Signaling bitrate limits (bps) for stability on poor connections.
# Defaults: 600000 (stream), 1200000 (screenshare).
SIGNALING_MAX_STREAM_BITRATE="600000"
SIGNALING_MAX_SCREEN_BITRATE="1200000"

# Optional shared secret for internal signaling clients.
# Leave empty to auto-generate on each setup run.
SIGNALING_INTERNAL_SECRET=""
