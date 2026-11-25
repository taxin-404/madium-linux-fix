# Madium on Linux — fixing the "Could not reach Madium" dead end

Madwine installs Madium fine, then Madium's own sign-in and setup fail with:

```
Could not reach Madium
```

and, at the install step:

```
Couldn't reach the Madium server: error sending request for url
(https://165.245.199.89/manifest.json) (after 3 CDN attempts)
```

## What's actually broken

Two separate things, and only one of them is on your machine.

**1. Public DNS for `getmadium.xyz` is parked.**

Every hostname under that zone answers `0.0.0.17` — a placeholder:

```
$ getent ahostsv4 auth.getmadium.xyz
0.0.0.17
$ getent ahostsv4 app.getmadium.xyz
0.0.0.17
```

Authoritative answers agree (checked against `8.8.8.8` and the local
resolver), so this is not your ISP filtering it and not `/etc/hosts` noise.

**But the API itself is alive.** The Cloudflare zone still routes the
hostname, so if you point `auth.getmadium.xyz` at a Cloudflare edge
yourself, it answers:

```
$ curl --resolve auth.getmadium.xyz:443:172.67.209.34 \
       https://auth.getmadium.xyz/api/v1/users/authenticated
{"message":"Route GET:/api/v1/users/authenticated not found", ...}
```

A 404 JSON body means you reached the real Fastify app. That is the whole
fix on this side.

**2. The content origin is a bare IP.**

Madium 2.9.9 fetches its payload from `https://165.245.199.89`, with a
valid Let's Encrypt certificate (including the IP SAN) and a manifest with
SHA-256 for every file. It was reachable from this machine:

```
$ curl -s https://165.245.199.89/manifest.json
{"version":"2.9.9","files":[ ... ]}
```

So if the installer still reports that URL as unreachable, retry it — the
endpoint comes and goes.

## The fix

```sh
./fix-dns.sh
```

which is just:

```
172.67.209.34 auth.getmadium.xyz
```

appended to `/etc/hosts` (requires root). Cloudflare anycast means other
edges work too; `104.21.53.53` was also answered for this zone.

Then restart Madium. Sign-in goes through and the setup wizard can reach
the manifest.

## Notes

- `172.67.209.34` came from historical DNS records for the same zone.
  If Cloudflare rotates it, re-resolve `download.getmadium.xyz` or
  `www.getmadium.xyz` and use one of those edges.
- `cdn.getmadium.me`, which Madwine 0.1.22 still calls for its ad links,
  is NXDOMAIN. That only breaks the "download the installer for me"
  button; supply `MadiumInstaller.exe` yourself and Madwine picks it up
  from `~/Downloads` (or set `installer` in `~/.config/madwine/config.json`).
- The Madium payload replaces `RobloxPlayerBeta.dll` in the Roblox
  version folder. Keep a copy of the original if you want to undo it.
- Verified 2026-11-25 against Madwine 0.1.22, Madium 2.9.9, installer 1.1.2.

Unofficial. Not affiliated with Madium, Madwine, Roblox or Cloudflare.
