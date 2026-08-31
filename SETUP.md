# Thinking Cube — OpenClaw on Oracle Cloud (Always Free)

This repo is the durable notes/runbook home for standing up a self-hosted
**OpenClaw** instance (open-source personal AI agent,
https://github.com/openclaw/openclaw, MIT licensed, formerly
Clawdbot/Moltbot) on an **Oracle Cloud Infrastructure (OCI) Always Free**
VM, acting as a persistent "thinking queue" sandbox.

> Security note: several sites ranking for "OpenClaw docs/setup" right now
> (e.g. `open-claw.bot`, `openclaw-ai.com`, `openclaws.io`, `openclaw.academy`,
> `oneclaw.net`, `clawtrust.ai`) are **not** the official project — they're
> SEO/content-farm lookalikes riding the project's virality, a common vector
> for malicious install scripts. Only trust `openclaw.ai`, `docs.openclaw.ai`,
> and `github.com/openclaw/openclaw`.

## Architecture decisions

- **Compute**: OCI Always Free `VM.Standard.A1.Flex` (Ampere ARM). As of the
  June 2026 Oracle policy change this tier is **2 OCPU / 12 GB RAM** total
  (down from the earlier 4/24) — still comfortably above OpenClaw's stated
  minimums (2 vCPU/4GB baseline, 8GB+ recommended if browser automation via
  Chromium is enabled).
- **OS**: Ubuntu 24.04 LTS (ARM64 image).
- **Deployment**: Docker + `docker-compose` (repo ships a
  `Dockerfile`/`docker-compose.yml`) rather than the bare `install.sh`,
  matching the "sandbox" isolation the user wants and giving a clean
  restart/upgrade story via `systemd`-managed Docker.
- **Networking**: default OCI "create VCN" flow (VCN + public subnet +
  Internet Gateway + security list). Only inbound SSH (22) needs to be open;
  OpenClaw talks to WhatsApp/Telegram outbound, no inbound webhook port
  required unless we later choose Telegram webhook mode over polling.
- **Region**: home region is **permanent** once the OCI account is created.
  US regions (Ashburn/Phoenix) are notorious for "out of host capacity" on
  Ampere A1; Frankfurt / Singapore / Tokyo have historically provisioned
  within minutes. Chosen region: _TBD, pick during signup_.
- **Secrets**: never committed to this repo. OCI API signing key, SSH
  private key, and the LLM API key (OpenClaw is bring-your-own-key) should
  live as environment variables on the Claude Code *environment* (so they
  persist across ephemeral session containers) rather than pasted fresh into
  chat each time, where practical.

## Runbook / status

- [x] Identify target agent → confirmed **OpenClaw**
- [x] Research OCI Always Free limits + OpenClaw resource requirements
- [ ] User creates OCI account (individual, not company) — **manual, gated
      on identity/card verification, cannot be automated**
- [ ] Generate OCI API signing key + collect OCIDs (user OCID, tenancy OCID,
      fingerprint, region) and hand to Claude via env vars
- [ ] Claude provisions VM.Standard.A1.Flex via `oci` CLI (VCN, subnet, SSH
      keypair, instance, cloud-init bootstrap)
- [ ] Install Docker, deploy OpenClaw via docker-compose
- [ ] Obtain an Anthropic API key (console.anthropic.com — separate from any
      Claude.ai subscription) or other LLM provider key for OpenClaw itself
- [ ] Run `openclaw onboard` and pair WhatsApp/Telegram — **requires the
      user's phone**, cannot be automated
- [ ] Verify 24/7 resilience (docker restart policy, survives VM reboot)

## Non-goals

Per the user: minimal code lives in this repo. It's notes/IaC/scripts only —
the actual running system lives on the Oracle VM.
