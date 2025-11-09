# Git Hooks

This directory contains custom git hooks to protect the repository from accidental secret commits.

## Pre-commit Hook: Secrets Detection

**Purpose:** Prevent accidentally committing private keys, API keys, passwords, and other sensitive credentials.

### Detected Patterns

The hook blocks files containing:
- Private key markers: `-----BEGIN PRIVATE KEY-----`
- RSA/EC key markers: `-----BEGIN RSA KEY-----`, `-----BEGIN EC KEY-----`
- OpenSSH key markers: `-----BEGIN OPENSSH PRIVATE KEY-----`
- Environment variables: `KEY`, `SECRET`, `TOKEN`, `PASSWORD` (in variable assignments)
- AWS/GitHub secrets: `AWS_SECRET`, `GITHUB_TOKEN`
- Age encryption: `AGE-SECRET-KEY`, `SOPS_AGE_KEY`
- 1Password references: `op://...`

### Safe Files

These files bypass the check (already encrypted or configuration):
- `secrets/*.yaml` - SOPS encrypted files
- `workflows/*.json` - Encrypted n8n workflows
- `.sops.yaml` - SOPS configuration

### Setup

Run once after cloning:
```bash
./scripts/setup-git-hooks.sh
```

This installs the hook to `.git/hooks/pre-commit`.

### Usage

The hook runs automatically on `git commit`. If secrets are detected:

```bash
❌ BLOCKED: Potential secret in <file>
ERROR: Secrets detected! To bypass: SKIP_PRECOMMIT=1 git commit
```

To bypass (use with caution):
```bash
SKIP_PRECOMMIT=1 git commit -m "message"
```

### Best Practices

1. Use 1Password references: `op://path/to/secret` instead of hardcoding
2. Encrypt sensitive data with SOPS before committing
3. Never commit plaintext secrets, even temporarily
