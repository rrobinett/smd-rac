# smd-rac

A **standalone, single-file** manager for a WsprDaemon **Remote Access Channel**
(RAC) — the `frpc` reverse tunnel that lets a station be reached through the
`gw2.wsprdaemon.org` gateway for SSH (and an optional web port).

It exists so you can bring a RAC tunnel up on a host that should **not** carry a
full WsprDaemon / sigmond install (e.g. a bare Proxmox host): clone this repo,
hand it a RAC ID and number, and it provisions everything itself.

```
git clone https://github.com/rrobinett/smd-rac.git
cd smd-rac

# one-time: provide the gateway credentials (see "Credentials" below)
sudo install -m 600 smd-rac.env.example /etc/sigmond/smd-rac.env
sudo $EDITOR /etc/sigmond/smd-rac.env          # fill in the two values

sudo ./smd-rac install --id AC0G/PROX --number 99
```

## What it does

`smd-rac install` performs the complete provisioning chain:

1. Downloads the `frpc` binary (v0.64.0) from GitHub to `/usr/local/sbin/frpc`.
2. Ensures an SSH keypair for gateway identity — reuses `~wsprdaemon/.ssh/id_*`
   if present, otherwise **generates a dedicated key** at
   `/etc/sigmond/frpc_id_rsa`.
3. Fetches the gateway's TLS CA cert to `/etc/sigmond/frps-ca.crt`.
4. Registers the station with the gateway (uploads a tiny tar over FTP so the
   server auto-creates the account and authorizes the key — non-fatal; `frpc`
   retries regardless).
5. Writes `/etc/sigmond/frpc.toml` (TLS + token auth; SSH proxy on
   `35800 + <number>`, web proxy on `45800 + <number>`).
6. Installs, enables, and starts `wd-rac.service`.

## Verbs

| Command | Action |
|---|---|
| `smd-rac` or `smd-rac status` | Show tunnel status (binary, config, service, gateway reachability) |
| `smd-rac install --id <ID> --number <N>` | Full provisioning (above). `--dry-run` to preview, `--yes` to skip prompts |
| `smd-rac start` \| `stop` \| `restart` | Lifecycle of `wd-rac.service` |

`--number` is assigned by the RAC administrator and sets your tunnel ports.
Numbers in `200–299` route through `vpn.hamsci.org` instead of `gw2`.

Mutating verbs need root and **auto-elevate via `sudo`** when run as a normal
user. Run `install --dry-run` first to see exactly what would change.

## Footprint

The only things it ever touches:

```
/usr/local/sbin/frpc                 frpc binary
/etc/sigmond/frpc.toml               tunnel config
/etc/sigmond/frpc_id_rsa[.pub]       dedicated keypair (if generated)
/etc/sigmond/frps-ca.crt             gateway TLS CA
/etc/systemd/system/wd-rac.service   the unit
```

## Requirements

System `python3` (3.11+ for `tomllib`), `ssh-keygen`, `systemd`, and outbound
network to GitHub (frpc download), `gw2.wsprdaemon.org:35736` (TLS), and the
gateway FTP. No virtualenv, no other dependencies. Tested on Debian 13.

## Credentials

This repo carries **no credentials**. The fleet-shared `frps` auth token and the
gateway FTP password are read at install time from the environment or from an
untracked env file, and written into the host's `/etc/sigmond/frpc.toml` (where
they belong) — never committed here.

| Variable | Purpose | Required |
|---|---|---|
| `WD_RAC_FRPS_TOKEN` | frps `[auth]` token, written into `frpc.toml` | yes (for `install`) |
| `WD_RAC_FTP_PASSWD` | gateway FTP password for one-time station auto-registration | no — tunnel registers on first spot upload if absent |
| `WD_RAC_FTP_USER` | gateway FTP user (default `noisegraphs`) | no |

Resolution order: real environment → `/etc/sigmond/smd-rac.env` (override the
path with `SMD_RAC_ENV`) → default. Supply them either way:

```bash
# env file (works regardless of how the script is run):
sudo cp smd-rac.env.example /etc/sigmond/smd-rac.env && sudo chmod 600 /etc/sigmond/smd-rac.env
# ...edit in the two values, then:
sudo ./smd-rac install --id AC0G/PROX --number 99

# or inline (must be root or use `sudo -E` so the vars survive):
sudo WD_RAC_FRPS_TOKEN=… WD_RAC_FTP_PASSWD=… ./smd-rac install --id AC0G/PROX --number 99
```

The two values are **not secret to this repo** — they are already published in
the upstream (public) WsprDaemon `smd` and are what the gateway expects every
RAC client to present. They are externalized here purely so this repository
contains no credential literals.

## Provenance & license

This is a faithful extraction of the `smd rac` logic from
[mijahauan/sigmond](https://github.com/mijahauan/sigmond)'s `smd`, repackaged as
an independent single-file tool. It is a **copy**, not a dependency — if the
upstream gateway host/port/token or registration flow changes, update the
constants here to match (the script header pins the source commit).

MIT licensed; see [LICENSE](LICENSE). The original copyright (Michael James
Hauan) is preserved as required.
