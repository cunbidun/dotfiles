# n8n Workflows

Encrypted n8n workflows managed via the dotfiles repository. Workflows are automatically encrypted with SOPS/age before commit.

## Prerequisites: Signal Bridge Setup

Before creating workflows, set up Signal Bridge for SMS notifications:

1. Tunnel API: `ssh -L 8080:127.0.0.1:8080 rpi5`
2. Generate QR: Open `http://localhost:8080/v1/qrcodelink?device_name=n8n-rpi5`
3. Link Device: Signal app → Settings → Linked devices → Scan QR
4. Verify: `curl -X POST http://127.0.0.1:8080/v2/send -d '{"number":"+16173966428","message":"test"}'`

## Quick Start

**Edit workflows:**
1. Open https://rpi5.tail9b4f4d.ts.net:5678 and edit in the UI
2. Test and save changes in n8n

**Sync to repository:**
```bash
./scripts/download-n8n-workflows.sh XRqp0ghHd2CX822C  # Download & encrypt
git add workflows/ && git commit -m "update workflows"
```

## Workflow Management

**View encrypted workflow:**
```bash
SOPS_AGE_KEY=$(op read "op://Infrastructure/SOPS Age Key/private key") sops decrypt workflows/<name>.json
```

**Note:** Encrypted workflows cannot be edited locally. Always make changes in the n8n UI at https://rpi5.tail9b4f4d.ts.net:5678, then download to sync changes to the repository.
