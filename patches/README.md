# Patches

Apply `*.patch` files to the upstream Kodi source (`KODI_REF`) in filename order, first from `patches/samba/`, then from `patches/kodi/`.

| Directory | Scope | Cache impact |
|---|---|---|
| `samba/` | `tools/depends/target/samba-gplv3/` | SMB dependencies only |
| `kodi/` | Kodi source and other target dependencies | Target dependencies and APK |

Generate patches with `git diff --binary` or `git format-patch`, relative to the source root. Patches must pass `git apply --check` on a clean upstream checkout.

Place changes to target dependencies other than Samba in `kodi/` to invalidate the target dependency cache.

`kodi/0002-smb-auth-prompt.patch` routes both `EPERM` and `EACCES` authentication failures to Kodi's credential prompt when the caller allows prompting. Background directory access remains noninteractive. Timeouts and missing shares do not trigger authentication prompts.
