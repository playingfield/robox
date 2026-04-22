# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Robox is a Packer-based project for building and distributing generic virtual machine boxes across dozens of Linux/BSD distributions and multiple virtualization providers. Boxes are distributed via Vagrant Cloud (namespaces: `generic`, `lavabit`, `lineage`) and container registries (Docker Hub, Quay.io).

## Key Commands

All operations are driven through the main orchestration script:

```bash
# Build a specific box (NAME format: DISTRO-PROVIDER, e.g. generic-ubuntu2204-libvirt)
./robox.sh box NAME

# Validate all Packer JSON templates (no actual build)
./robox.sh validate

# Build all boxes for a provider
./robox.sh vmware
./robox.sh libvirt
./robox.sh virtualbox
./robox.sh docker
./robox.sh hyperv
./robox.sh parallels

# Build all boxes for a namespace
./robox.sh generic
./robox.sh magma
./robox.sh lineage
./robox.sh developer

# Update ISO URLs and checksums
./robox.sh isos
./robox.sh sums

# Cache ISOs locally
./robox.sh cache

# Cleanup build artifacts
./robox.sh cleanup
./robox.sh distclean
```

## Architecture

### Naming Convention

Packer templates follow the pattern `NAMESPACE-DISTRO-PROVIDER.json`:
- **Namespaces**: `generic`, `magma`, `developer`, `lineage`
- **Providers**: `vmware`, `virtualbox`, `libvirt`, `hyperv`, `parallels`, `docker`
- Example: `generic-ubuntu2204-libvirt.json`

### Build Flow

1. `robox.sh` invokes `packer build` on a JSON template
2. Packer downloads the OS ISO (or uses cached copy from `PACKER_CACHE_DIR`)
3. The builder boots the ISO using a kickstart/preseed from `http/`
4. Provisioning scripts in `scripts/DISTRO/` configure the OS (networking, package manager, hypervisor tools, vagrant user, cleanup)
5. Packer outputs a `.box` file ready for Vagrant Cloud upload

### Directory Structure

- **`scripts/DISTRO/`** — Per-distro bash provisioning scripts run by Packer post-install. Common scripts: `base.sh`, `network.sh`, `vagrant.sh`, `cleanup.sh`, plus hypervisor-specific (`vmware.sh`, `virtualbox.sh`) and package manager scripts.
- **`http/`** — Kickstart (`.ks`), preseed (`.cfg`), and cloud-init files served by Packer's HTTP server during OS installation. Named `generic.DISTRO.VERSION.ks` etc.
- **`tpl/`** — Vagrantfile templates for each namespace (`generic/`, `lavabit/`, `lineage/`, `roboxes/`).
- **`check/`** — Validation template configs per distro (`.tpl` files).
- **`res/scripts/`** — Helper scripts for box addition, release management, upload, and verification.
- **`packer-cache-*.json`** — Templates used only to pre-fetch ISOs without building.

### Environment and Credentials

On first run, `robox.sh` creates `.credentialsrc` with stubs for:
- `VAGRANT_CLOUD_TOKEN` — Vagrant Cloud API token
- `DOCKER_USERNAME` / `DOCKER_PASSWORD` — Docker Hub credentials  
- `QUAY_USERNAME` / `QUAY_PASSWORD` — Quay.io credentials

Key Packer environment variables set by `robox.sh`:
- `GOMAXPROCS=2`, `PACKER_MAX_PROCS=1` — Sequential builds to avoid resource exhaustion
- `PACKER_ON_ERROR=cleanup` — Auto-cleanup on failure
- `PACKER_CACHE_DIR` — ISO cache location

### CI/CD

`.github/workflows/robox.yml` runs daily at 12:00 UTC and on push/PR to validate all Packer JSON templates via `packer validate`. No actual builds run in CI.

## UTM Build Target (macOS only)

UTM support uses the [`github.com/naveenrajm7/utm`](https://github.com/naveenrajm7/utm) Packer plugin. Install it once before building:

```bash
packer plugins install github.com/naveenrajm7/utm
```

UTM templates (`generic-utm-x64.json`, `generic-utm-a64.json`, `ansiblebook-utm-*.json`) use:
- Builder type `utm-iso` instead of `qemu`
- Post-processor `utm-vagrant` instead of `vagrant`  
- `scripts/common/utm.sh` to install SPICE guest tools (`spice-vdagent`, `qemu-guest-agent`, `spice-webdavd`)

`generic-utm-a64.json` targets Apple Silicon (aarch64) natively with `uefi_boot: true` and `hypervisor: true`. Build via:

```bash
./robox.sh utm           # builds generic-utm-x64 + generic-utm-a64
./robox.sh ansiblebook   # includes UTM on macOS
```

## Debian 13 (Trixie) ISO Checksum

The `ansiblebook-debian13` builder uses a placeholder checksum (`sha256:000...`). Before building, update it with the real checksum:

```bash
# Get the real checksum from Debian mirrors
curl -s https://cdimage.debian.org/cdimage/release/13.0.0/amd64/iso-cd/SHA256SUMS | grep netinst
# Then update iso_checksum in ansiblebook-vmware-x64.json and ansiblebook-libvirt-x64.json
# Or run: ./robox.sh sums
```

## Adding or Updating a Distribution

1. Create/update the Packer JSON template(s): `NAMESPACE-DISTRO-PROVIDER.json`
2. Add/update the OS installation file in `http/` (kickstart, preseed, or cloud-init)
3. Add/update provisioning scripts in `scripts/DISTRO/`
4. Update ISO URLs/checksums in the template (use `./robox.sh isos` and `./robox.sh sums` as helpers)
5. Validate: `./robox.sh validate`
