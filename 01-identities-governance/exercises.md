# Today's Focus: Identities & Governance — Concepts + Hands-On Exercises

Domain 1 is 20–25% of AZ-104 — the single highest-weighted domain alongside Compute — and everything else in the exam sits on top of it (you can't do a storage/compute/networking lab without understanding scope and role assignment first). Budget today roughly: 45–60 min reading the concepts below, then work exercises 1–8 in order (Portal → CLI/PowerShell → Bicep for each), ~45–60 min per exercise including verification. That's a full ~8 hour session; stop whenever you need to and pick up the next exercise next time — nothing here is time-boxed to finish in one sitting.

This is a **workbook**, not a walkthrough: each exercise gives you an objective and a hint, not the finished command. Try it yourself first using the Portal and `az`/`Get-Help`/`--help` docs. Full reference commands for every task are in `study-guide.md` in this same folder if you get stuck — and a **Solutions & Verification** section sits at the bottom of this file for a quick self-check once you've attempted each one.

---

## Core Concepts

### 1. Entra ID vs. "Azure resources" — two different worlds

Microsoft Entra ID (formerly Azure AD) is Microsoft's identity platform — it holds users, groups, licenses, and authentication policy, and it's **tenant-scoped**, not subscription-scoped. Azure Resource Manager (ARM) — subscriptions, resource groups, VMs, storage accounts, etc. — is a *separate* system that happens to trust Entra ID for authentication. This is why, later, you'll notice Bicep/ARM can deploy a role *assignment* but can't create an Entra *user* or *group* — those are a Microsoft Graph concern, managed via PowerShell/CLI/Portal, not ARM templates. Keep this boundary in your head; the exam tests it directly ("which of these can be deployed via an ARM template?").

### 2. RBAC — the exact anatomy of "who can do what, where"

A role assignment is always **three things bound together**:

- **Security principal** — the *who*: a user, a group, a service principal (app identity), or a managed identity.
- **Role definition** — the *what*: a named bundle of permitted actions (e.g. Contributor = manage everything except access/policy; Reader = view only; Owner = Contributor + can manage access). Azure ships dozens of built-in roles; you can also author custom roles.
- **Scope** — the *where*: exactly one of **management group → subscription → resource group → resource**, in a strict parent-child hierarchy. A role granted at a higher scope is **inherited** by everything below it — grant Contributor at the subscription and every resource group and resource in it inherits Contributor for that principal.

Memorize this scope order — it's the backbone of nearly every "least privilege" scenario question:

```
Management Group  (broadest — can span many subscriptions)
  └─ Subscription
       └─ Resource Group
            └─ Resource   (narrowest — one VM, one storage account, etc.)
```

A handful of built-in roles you must know cold for the exam:

| Role | What it allows |
|---|---|
| **Owner** | Full control, including managing access (RBAC) for others |
| **Contributor** | Full control over resources, but **cannot** manage access/RBAC |
| **Reader** | View everything, change nothing |
| **User Access Administrator** | Manage *only* role assignments — doesn't grant resource control itself |

*Exam trap:* Contributor cannot grant someone else access — that needs Owner or User Access Administrator. This distinction shows up constantly.

### 3. Azure Policy — a different question entirely

RBAC answers **"can this identity perform this action."** Azure Policy answers **"is this resource configuration allowed to exist at all," regardless of who's deploying it.** An Owner with full RBAC rights can still be blocked from creating a VM in the wrong region, or from creating a storage account without HTTPS-only enabled, if a Policy says no.

Structure: a **policy definition** (the rule) is grouped into an **initiative** (a set of related policy definitions, e.g. "CIS benchmark") and applied via a **policy assignment** at some scope (same management group/subscription/RG/resource hierarchy as RBAC, and also inherited downward).

Every policy definition has exactly one **effect**, and the effects matter a lot for the exam:

| Effect | What it does |
|---|---|
| `deny` | Blocks the create/update request outright |
| `audit` | Allows it, but flags the resource non-compliant in a report |
| `append` | Adds a field/value to the request before it's created (e.g. force a tag) |
| `modify` | Like append but can also alter/remove existing properties |
| `deployIfNotExists` | After creation, deploys a related resource if it's missing (e.g. auto-attach a diagnostic setting) |
| `auditIfNotExists` | Same idea as above but only reports, doesn't deploy |
| `disabled` | Turns the rule off without deleting the assignment |

Order of evaluation matters: `append`/`modify` run first (they can change the request), then `deny`, then `audit`, then the `*IfNotExists` effects after the resource provider accepts the request. You don't need to memorize the full order, but know that **deny happens before audit** (so you never get a duplicate audit log for something that was already blocked).

### 4. Resource locks — a third, independent control

Locks (`CanNotDelete`, `ReadOnly`) are neither RBAC nor Policy — they're a blunt, scope-inherited switch that overrides *everyone*, including Owners. A `CanNotDelete` lock stops deletion regardless of role; a `ReadOnly` lock blocks all writes, including RBAC role assignment changes on that resource. Locks are for "this must never be accidentally deleted," not for day-to-day access control.

### 5. Tags, resource groups, subscriptions, management groups — the org chart

**Tags** are key-value metadata (`env=prod`, `owner=platform-team`) used for cost reporting, automation targeting, and Policy conditions (you can require or auto-append tags via a Policy `append`/`modify` effect — see above). **Resource groups** are the unit of lifecycle management — most things you deploy, back up, or delete together live in one RG. **Subscriptions** are the unit of billing and a hard boundary for some quotas. **Management groups** let you apply RBAC/Policy across multiple subscriptions at once — think "one policy for the whole company" vs. "one policy for one team's subscription."

### 6. Cost visibility

**Budgets** (Cost Management) alert you when spend crosses a threshold — they don't block anything, they just notify. **Azure Advisor** separately gives cost *recommendations* (e.g. "this VM is underutilized, resize it") based on actual usage patterns, distinct from a budget alert.

---

## Setup for today

Reuse the sandbox pattern from the overview doc. If you haven't already:

```bash
az login
az group create --name rg-az104-identity --location westeurope
```

Set a low budget alert on your subscription in Cost Management before you start creating resources (see Exercise 8).

---

## Exercises

### Exercise 1 — Users and a security group (Portal, then CLI/PowerShell)

**Objective:** Create two test users and a security group containing both, entirely via the Portal first.

**Then repeat via CLI or PowerShell** — create the same two users and group with commands instead of clicks.

*Hint:* Entra ID → Users / Groups. For CLI, look at `az ad user create` and `az ad group create` — you'll need `--force-change-password-next-sign-in` and a temporary password meeting complexity rules.

### Exercise 2 — Scope the access correctly

**Objective:** Grant your new group **Contributor** on `rg-az104-identity` only — not on the whole subscription. Confirm via Access Control (IAM) → "View access" that both users inherit it through the group, not as a direct assignment.

**Then:** try (and expect to fail, or note what *would* happen) granting one of the individual users **Reader** directly on just one resource inside that group, and reason through what their *effective* permission would be on that one resource (hint: RBAC is additive — the more permissive of any applicable assignments wins).

*Hint:* `az role assignment create` needs `--assignee-object-id`, `--role`, and a `--scope` or `--resource-group`. Use `--assignee-principal-type Group` since you're assigning to a group, not a user.

### Exercise 3 — Codify the role assignment in Bicep

**Objective:** Write a Bicep file that creates the same Contributor role assignment from Exercise 2, parameterized so `principalId` is passed in at deploy time. Deploy it with `az deployment group create`, then change the role to **Reader** and redeploy — confirm in the Portal that the assignment updated in place rather than creating a duplicate.

*Hint:* The resource type is `Microsoft.Authorization/roleAssignments`. You'll need the **role definition GUID**, not the display name — look up "Azure built-in roles" for the Contributor and Reader GUIDs. The assignment's `name` property must be a deterministic GUID (`guid(...)`) or redeploys will create duplicates instead of updating.

### Exercise 4 — Policy: block a region

**Objective:** Assign a built-in policy that restricts allowed resource locations to your home region only, scoped to `rg-az104-identity`. Try creating a resource (any cheap one, e.g. a storage account) in a *different* region and confirm it's denied. Read the actual error message Azure gives you — it names the policy that blocked you.

**Then:** find the same policy assignment in the Portal's Policy → Compliance view and check its compliance state.

*Hint:* Search Policy → Definitions for "Allowed locations." Note its effect is `deny`.

### Exercise 5 — Policy: enforce a tag automatically

**Objective:** Assign a built-in or custom policy with an `append` or `modify` effect that automatically adds a tag (e.g. `costCenter=lab`) to any resource created in `rg-az104-identity` that doesn't already have it. Create a new resource without setting that tag yourself, then confirm the tag appeared automatically.

*Hint:* Search built-in policy definitions for "Append a tag" or "Modify" — there are ready-made ones you don't need to author from scratch.

### Exercise 6 — Locks vs. RBAC

**Objective:** Add a `CanNotDelete` lock to `rg-az104-identity`. As the account you're logged in with (which likely has Owner), try to delete the resource group and confirm it's blocked — note that the error is about the *lock*, not about permissions.

**Then:** try to delete just one resource inside the group (not the group itself) — reason about whether the lock protects individual resources too (it does, since locks are inherited downward just like RBAC and Policy).

*Hint:* `az lock create` / `az lock delete`. Remove the lock before you try to tear the resource group down at the end of the session, or the teardown will fail.

### Exercise 7 — Management group (view-only, if your account allows it)

**Objective:** If your subscription has management-group creation rights (a personal/free account usually does — you're the Global Admin), create one management group and move your subscription under it. Assign Reader at the management-group level and reason through what that means for *every* subscription under it, present or future.

*Hint:* This is enterprise-admin territory in real organizations — the goal here is just to see the hierarchy exist once, not to build a deep tree.

### Exercise 8 — Budgets and Advisor

**Objective:** Create a monthly budget on your subscription with an alert at 80% of a small threshold (e.g. €10). Separately, open Azure Advisor's Cost tab and read through whatever recommendations exist for your subscription (even a near-empty sandbox often has at least one, e.g. an idle resource suggestion).

*Hint:* Cost Management + Billing → Budgets → Add. Advisor is its own top-level Portal blade.

---

## Solutions & Verification

Don't read this until you've attempted the exercise — the point is the struggle of finding the right blade/command yourself.

**Ex. 1–3 (users, group, RBAC, Bicep):** Full commands (Portal, CLI, PowerShell, and a working Bicep file) are in `study-guide.md` → "Lab 1 — Users, groups, and RBAC" in this same folder.

**Ex. 4–5 (Policy):** Full commands and a working Bicep policy-assignment snippet are in `study-guide.md` → "Lab 2 — Azure Policy and resource locks."

**Ex. 6 (Locks):** Same section as above, `az lock create --lock-type CanNotDelete`.

**Ex. 7–8 (Management groups, tags, budgets):** `study-guide.md` → "Lab 3 — Tags, budgets, management groups."

**Verification checklist — confirm you can answer these without notes before moving on:**
- [ ] Can you state, from memory, the four RBAC scope levels in order?
- [ ] Can you explain why Contributor ≠ Owner in one sentence?
- [ ] Can you explain the difference between what RBAC controls and what Policy controls?
- [ ] Do you know which Policy effect you'd use to *block* vs. *auto-fix* vs. *just report* a non-compliant resource?
- [ ] Do you know that a lock overrides even an Owner, and that it's independent of both RBAC and Policy?
- [ ] Can you name the ARM resource type for a role assignment (`Microsoft.Authorization/roleAssignments`) and explain why Entra users/groups themselves can't be created the same way?

## Gaps / review-later

*(Add anything that felt shaky today — pull these into your Week-12 review agenda.)*

---

**Cleanup:** remove the `CanNotDelete` lock, then `az group delete --name rg-az104-identity --yes` to zero out cost before you finish for the day.

**Want to be quizzed instead of reading?** Invoke the `az104-identity-governance` skill — it'll run scenario questions against this exact material.
