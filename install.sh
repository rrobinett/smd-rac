#!/usr/bin/env bash
#
# install.sh — convenience installer for the smd-rac RAC tunnel.
#
# Defines default values for the two credentials that `smd-rac install` needs,
# then runs it — so you can deploy with a single command and no env-file step:
#
#     sudo ./install.sh --id AC0G/B4-PROXMOX --number 147
#
# Any smd-rac install arguments (--id, --number, --dry-run, --yes) pass through.
#
# The two defaults below are the fleet-shared constants already published in the
# public WsprDaemon `smd`; they are what the gateway expects every RAC client to
# present. Override either one by exporting it before running this script, e.g.:
#
#     WD_RAC_FRPS_TOKEN=… sudo -E ./install.sh --id … --number …
#
set -euo pipefail

# Elevate to root first, preserving any pre-set WD_RAC_* overrides, so the
# credentials survive into smd-rac (sudo would otherwise strip them when
# smd-rac auto-elevates).
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -E -- "$0" "$@"
fi

# Default credentials (only set if not already provided in the environment).
: "${WD_RAC_FRPS_TOKEN:=e6fe04d781252e10b89b1ec490e005df}"
: "${WD_RAC_FTP_PASSWD:=xahFie6g}"
export WD_RAC_FRPS_TOKEN WD_RAC_FTP_PASSWD

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/smd-rac" install "$@"
