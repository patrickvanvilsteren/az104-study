# AZ-104 Study Workspace

Hands-on study workspace for the AZ-104 Microsoft Azure Administrator exam. Open this folder in VS Code.

## Structure

```
az104-study/
├── 00-overview-and-study-plan.md   ← start here: pacing, tooling setup, weekly cadence
├── 01-identities-governance/
│   ├── study-guide.md              ← concepts, hands-on labs (Portal/CLI/PowerShell/Bicep), checklist
│   └── bicep/                      ← your .bicep files for this domain's labs go here
├── 02-storage/
│   ├── study-guide.md
│   └── bicep/
├── 03-compute/
│   ├── study-guide.md
│   └── bicep/
├── 04-networking/
│   ├── study-guide.md
│   └── bicep/
└── 05-monitor-backup/
    ├── study-guide.md
    └── bicep/
```

## How to use it

1. Read `00-overview-and-study-plan.md` first — one-time tooling setup and the week-by-week pacing plan.
2. Work through each domain folder in order. Each `study-guide.md` walks the same lab three ways: Portal (GUI), PowerShell/Azure CLI, then Bicep.
3. As you write Bicep for a domain's labs, save the `.bicep` files into that domain's `bicep/` folder — by the end you'll have a personal IaC module library across identity/RBAC, storage, compute, networking, and monitoring/backup. Consider turning this whole folder into a git repo (`git init` here) so it doubles as a portfolio project.
4. Each `study-guide.md` ends with a "Gaps / review-later list" — jot down anything shaky as you go; that becomes your final review agenda.

## Companion tools

- These same study guides also live in your **"Learning Azure AZ-104" Claude Project** (kept in sync as the source of truth) — useful if you want to search/reference them from a Claude chat.
- Five **AZ-104 study-companion skills** (`az104-identity-governance`, `az104-storage`, `az104-compute`, `az104-networking`, `az104-monitor-backup`) are available in Claude — invoke one any time you want to be quizzed or drilled on a domain instead of reading.

## Exam reference

Skills outline effective April 17, 2026, passing score 700. Source: [Microsoft Learn AZ-104 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104).
