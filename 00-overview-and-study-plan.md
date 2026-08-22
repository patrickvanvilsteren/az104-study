# AZ-104 Study Plan — Overview

**Exam:** AZ-104 Microsoft Azure Administrator | Passing score: 700 | Skills outline effective April 17, 2026
**Your pace:** ~12 hrs/week | **Approach:** every topic built three ways — Portal (GUI), PowerShell + Azure CLI, and Bicep — because that progression (click it, script it, codify it) is exactly how real Cloud/Platform Engineering roles work, and it's the fastest path from "certified" to "hireable."

## Why this structure

Each domain below is its own folder/doc with the same five sections: concepts, why it matters on the job, three-way hands-on labs, a design-scenario challenge, and an exam checklist pulled straight from the official skills outline. You build the same resource three times with three tools, which cements the underlying Azure concepts (not just button locations) and gives you Bicep reps — the actual skill that leads into your IaC/platform-engineering goal.

## Domain weighting (informs time allocation)

| # | Domain | Exam weight | Suggested weeks (of 12) |
|---|---|---|---|
| 1 | Manage Azure Identities and Governance | 20–25% | Weeks 1–2 |
| 2 | Implement and Manage Storage | 15–20% | Weeks 3–4 |
| 3 | Deploy and Manage Azure Compute Resources | 20–25% | Weeks 5–7 |
| 4 | Implement and Manage Virtual Networking | 15–20% | Weeks 8–9 |
| 5 | Monitor and Maintain Azure Resources | 10–15% | Weeks 10–11 |
| — | Full practice exams + weak-area review | — | Week 12 |

At 12 hrs/week that's roughly 2 hrs concept reading + 8 hrs hands-on labs + 2 hrs review/flashcards each week. Compute gets 3 weeks because it's both heavily weighted and the densest (VMs, scale sets, containers, App Service).

## One-time setup (do this before Week 1)

1. **Azure subscription** — sign up for a free account (search "Azure free account" for current offer terms) or use Visual Studio/MSDN credit if your employer provides one. Set a **budget alert at a low threshold (e.g. €10)** immediately in Cost Management — you'll be creating and deleting resources constantly.
2. **Tooling on your machine:**
   - [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) — `az --version` to confirm
   - [Az PowerShell module](https://learn.microsoft.com/powershell/azure/install-azure-powershell) — `Install-Module -Name Az -Scope CurrentUser`
   - [VS Code](https://code.visualstudio.com/) + Bicep extension + Azure Account extension
   - [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install) (or let the VS Code extension manage it)
3. **Login test:** `az login` and `Connect-AzAccount` — confirm both authenticate against your subscription.
4. **A "sandbox" resource group** you tear down weekly, e.g. `rg-az104-lab`, so cost stays near zero and you build the habit of cleaning up after labs (a real operational skill).
5. **A GitHub repo** (e.g. `az104-bicep-labs`) to commit every Bicep file you write. This becomes a portfolio artifact for job applications — don't skip it.

## Cadence per topic (repeat for each domain)

1. Skim the concept section (30–45 min) — don't over-read theory, you'll absorb it through labs.
2. Do the **Portal lab** — see it, understand the resource's shape and settings.
2. Do the **PowerShell/CLI lab** — same resource, scripted. Notice which parameters map to which portal fields.
3. Do the **Bicep lab** — same resource again, declaratively. Deploy it, then intentionally change one property and redeploy to see idempotency in action.
4. Tear the resource group down (`az group delete` / `Remove-AzResourceGroup`) — reinforces that infra is disposable and re-creatable, the core IaC mindset.
5. Attempt the **design-scenario challenge** at the end of the topic doc without notes.
6. Run through the **exam checklist** and flag anything shaky for review week.

## Where things live

- This project holds one study-guide doc per domain (`az104/01-...` through `az104/05-...`), each with the structure above.
- A companion **skill** per domain (delivered separately) acts as a quiz/review buddy — invoke it any time you want to be drilled on that topic instead of reading.
- Track weak areas in a running "gaps" list at the bottom of each domain doc as you go — that list becomes your Week 12 review agenda.

## Career throughline (keep this in view)

AZ-104 is the credential; the actual goal is Cloud/Platform Engineer specializing in IaC and automation. That means: don't just pass labs in the Portal and stop — the Bicep rep is the one that compounds. By the time you finish all 5 domains you should have a personal Bicep module library covering identity/RBAC, storage accounts, VMs/App Service, networking, and monitoring — reusable in real work and demonstrable in interviews.
