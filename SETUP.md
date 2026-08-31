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

## Why execution happens in OCI Cloud Shell, not directly from Claude

This Claude Code session runs in a sandboxed cloud container whose outbound
network is restricted to a policy-enforcing proxy. `*.oraclecloud.com` is
explicitly denied by that policy (confirmed via the proxy's own connection
log — a 403 policy denial, not a bug), and raw SSH (port 22) is blocked
outbound entirely regardless of destination. So Claude cannot call the OCI
API or SSH into the resulting VM directly from this session — that's a
deliberate boundary, not something to route around.

The fix: **OCI Cloud Shell** (built into the OCI Console, browser-based,
already authenticated as you, Terraform + git preinstalled, full internet
access). Claude authors all the actual infrastructure code (this repo); you
run a handful of copy-paste commands in Cloud Shell to apply it. See
[`infra/terraform/`](infra/terraform/) and the runbook below.

## Architecture decisions

- **Compute**: OCI Always Free `VM.Standard.A1.Flex` (Ampere ARM), 2 OCPU /
  12 GB RAM (the tier was halved from 4/24 in June 2026) — still
  comfortably above OpenClaw's stated minimums (2 vCPU/4GB baseline, 8GB+
  recommended with Chromium browser automation enabled).
- **OS**: Ubuntu 24.04 LTS (ARM64).
- **Provisioning**: Terraform, applied from OCI Cloud Shell (see above) —
  not the OCI CLI from this session, and not click-ops in the Console.
- **Networking**: dedicated VCN + public subnet + Internet Gateway +
  security list, inbound SSH (22) only. OpenClaw talks to WhatsApp/Telegram
  outbound; no inbound webhook port needed unless we later switch Telegram
  to webhook mode over polling.
- **Region**: `us-phoenix-1` — this was fixed at account creation and can't
  be changed without a new account. US regions are the most likely to hit
  "Out of host capacity" on Ampere A1; `availability_domain_index` in
  `infra/terraform/variables.tf` can be bumped (0/1/2) and re-applied if
  that happens.
- **First-boot automation**: cloud-init installs Docker + prerequisites
  unattended, and starts Watchtower (auto-updates/restarts any running
  container, including OpenClaw once deployed, daily) so ongoing
  maintenance doesn't need SSH or manual relay either. Installing OpenClaw
  itself and pairing WhatsApp/Telegram is left for an interactive SSH
  session (via Cloud Shell) — that step needs a human for the QR-code
  pairing regardless, so it runs against the live official installer rather
  than a copy baked into this repo.
- **Day-to-day use**: once OpenClaw is live, you interact with it directly
  over WhatsApp/Telegram — not through Claude relaying commands. The
  Cloud-Shell copy/paste is a one-time (or rare) provisioning cost, not a
  recurring one.
- **Secrets**: never committed here (see `.gitignore`). The OCI API key you
  originally provided already passed through the chat transcript and turned
  out to be unusable from this session anyway (network policy) — it's been
  deleted from local disk. **Recommendation: rotate it** (OCI Console →
  Profile → API keys → delete the old one, add a new one) since it's not
  needed for the Cloud-Shell-based approach at all.

## Runbook / status

- [x] Identify target agent → confirmed **OpenClaw**
- [x] Research OCI Always Free limits + OpenClaw resource requirements
- [x] User creates OCI account (individual) — done, home region `us-phoenix-1`
- [x] Discover this session can't reach `*.oraclecloud.com` or SSH out —
      pivoted to Cloud Shell + Terraform
- [x] Author Terraform (VCN/subnet/IGW/security list/instance/cloud-init) —
      see `infra/terraform/`
- [x] User runs Terraform apply in OCI Cloud Shell — VM live in `us-phoenix-1`
      (public IP intentionally not committed here; run `terraform output` in
      Cloud Shell from `infra/terraform/` to retrieve it)
- [x] SSH in (via Cloud Shell), install OpenClaw, onboard (agent
      `Thinking_Cube_Test_v1`, access mode: full)
- [x] Configure LLM: **DeepSeek V4 Pro** (not Anthropic — user's choice), as a
      custom OpenAI-compatible provider via `openclaw config set`
      (`models.providers.deepseek`, `agents.defaults.models` allowlist,
      `agents.defaults.model.primary`). Live-verified via
      `openclaw infer model run` — real 200 from api.deepseek.com.
- [ ] Pair WhatsApp/Telegram — **requires the user's phone**
- [ ] Verify 24/7 resilience (docker restart policy, survives VM reboot)

### Working notes

- `containrrr/watchtower` is archived/unmaintained (Dec 2025); cloud-init now
  uses `nickfedor/watchtower` instead.
- Cloud Shell runs in FIPS mode — `ssh-keygen -t ed25519` fails silently
  there; use `-t rsa -b 4096`.
- Always run VM commands as `ssh ... '<command>'` (command as a single ssh
  argument), never a bare `ssh host` followed by separate pasted commands —
  the latter doesn't hold a persistent session in this workflow and commands
  silently land in Cloud Shell instead of the VM.
- OpenClaw's own docs (docs.openclaw.ai) are blocked by this Claude session's
  network policy, same as Oracle's and DeepSeek's. Working pattern: ask the
  user to fetch a specific doc URL and paste its content back.
- `openclaw config set ... --dry-run` validates against the real schema
  without writing — use it before every non-trivial config write.

## Next step: apply the Terraform, in OCI Cloud Shell

Open Cloud Shell from the OCI Console (top-right icon), then:

```bash
git clone https://github.com/cybercryptixcoder/Thinking-Cube.git
cd Thinking-Cube
git checkout claude/openclop-cloud-run-setup-diieos
cd infra/terraform

ssh-keygen -t rsa -b 4096 -f ~/.ssh/openclaw_vm -N ""   # Cloud Shell runs in FIPS mode; ed25519 is rejected there

terraform init
terraform apply \
  -var="compartment_ocid=ocid1.tenancy.oc1..aaaaaaaa4f5zvqgprffewg3q6n75i6adn3fsldydl2laiie3kv5rcdiom7pq" \
  -var="ssh_public_key=$(cat ~/.ssh/openclaw_vm.pub)"
```

Review the plan, type `yes` to apply. If it fails with **"Out of host
capacity"**, either re-run the same command a few times over the next
minutes/hours, or edit `-var="availability_domain_index=1"` (then `2`) and
retry — or use this retry loop instead of a single apply:

```bash
until terraform apply -auto-approve \
  -var="compartment_ocid=ocid1.tenancy.oc1..aaaaaaaa4f5zvqgprffewg3q6n75i6adn3fsldydl2laiie3kv5rcdiom7pq" \
  -var="ssh_public_key=$(cat ~/.ssh/openclaw_vm.pub)"; do
  echo "retrying in 60s..."; sleep 60
done
```

When it succeeds, paste the `instance_public_ip` output back into this
conversation and Claude will give you the exact next commands (SSH in via
Cloud Shell, install OpenClaw, onboard).

## Non-goals

Per the user: minimal code lives in this repo. It's notes/IaC/scripts only —
the actual running system lives on the Oracle VM.
