# Domain 1 — Manage Azure Identities and Governance (20–25%)

## Concepts

Azure's identity layer is **Microsoft Entra ID** (formerly Azure AD) — a separate service from "Azure resources," which trips people up early. Entra ID holds users, groups, and licenses; **Azure RBAC** (built-in roles assigned at management group / subscription / resource group / resource scope) controls *who can do what to a resource*; **Azure Policy** controls *what resources are even allowed to look like* (enforced compliance, not just permissions); and **management groups → subscriptions → resource groups → resources** is the governance hierarchy everything inherits down.

The distinction that shows up constantly on the exam and on the job: **RBAC answers "can this identity perform this action," Policy answers "is this configuration allowed to exist at all."** A user can have Owner RBAC and still be blocked by Policy from deploying a VM outside an allowed region.

## Why it matters on the job

This is the domain that maps directly to enterprise IT operations — the world you're already in. Every ServiceNow access request, every "why can't I see this resource group," every cost overrun that should have had a budget alert, every "someone deployed a resource in the wrong region" incident traces back to identity, RBAC, or Policy being under- or over-configured. It's also the foundation every other domain sits on: you can't do storage, compute, or networking labs without understanding scope and role assignment first.

## Hands-on labs

### Lab 1 — Users, groups, and RBAC

**Portal:**
1. Entra ID → Users → create 2 test users (e.g. `az104-alice`, `az104-bob`).
2. Entra ID → Groups → create a security group `az104-lab-admins`, add both users.
3. Resource Groups → create `rg-az104-identity` → Access control (IAM) → assign the built-in **Contributor** role to `az104-lab-admins` scoped to that resource group only.
4. Access control (IAM) → View access → confirm both users inherit Contributor via the group.

**PowerShell / CLI (same task):**
```powershell
New-AzADUser -DisplayName "az104-alice" -UserPrincipalName "az104-alice@<yourtenant>.onmicrosoft.com" -MailNickname "alice" -Password (ConvertTo-SecureString "P@ssw0rd1234!" -AsPlainText -Force)
$group = New-AzADGroup -DisplayName "az104-lab-admins" -MailNickname "az104labadmins" -SecurityEnabled
New-AzResourceGroup -Name rg-az104-identity -Location westeurope
New-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName "Contributor" -ResourceGroupName rg-az104-identity
```
```bash
az ad user create --display-name az104-alice --user-principal-name "az104-alice@<yourtenant>.onmicrosoft.com" --password "P@ssw0rd1234!" --force-change-password-next-sign-in true
az ad group create --display-name az104-lab-admins --mail-nickname az104labadmins
az group create --name rg-az104-identity --location westeurope
az role assignment create --assignee-object-id <group-object-id> --assignee-principal-type Group --role Contributor --resource-group rg-az104-identity
```

**Bicep (role assignment as code — this is the pattern used in real platform teams):**
```bicep
// role-assignment.bicep
@description('Object ID of the group or user to grant access to')
param principalId string
param principalType string = 'Group'

@description('Built-in role definition ID for Contributor')
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, contributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: principalId
    principalType: principalType
  }
}
```
Deploy with: `az deployment group create --resource-group rg-az104-identity --template-file role-assignment.bicep --parameters principalId=<group-object-id>`

*Note: Entra ID users/groups themselves aren't managed by ARM/Bicep (that's a Microsoft Graph concept) — this is why the role assignment is what you codify, while user/group provisioning stays a PowerShell/CLI or Graph task. Good exam nuance to internalize.*

### Lab 2 — Azure Policy and resource locks

**Portal:** Policy → Assignments → assign the built-in policy "Allowed locations" scoped to `rg-az104-identity`, restrict to your home region only. Then try creating a resource in a disallowed region and watch it get denied. Then go to the resource group → Locks → add a **CanNotDelete** lock and try deleting the group.

**CLI:**
```bash
az policy assignment create --name allowed-locations --display-name "Allowed Locations" \
  --policy "e56962a6-4747-49cd-b67b-bf8b01975c4c" \
  --params '{"listOfAllowedLocations":{"value":["westeurope"]}}' \
  --resource-group rg-az104-identity
az lock create --name dont-delete-me --lock-type CanNotDelete --resource-group rg-az104-identity
```

**Bicep:**
```bicep
resource allowedLocations 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'allowed-locations'
  scope: resourceGroup()
  properties: {
    policyDefinitionId: subscriptionResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
    parameters: {
      listOfAllowedLocations: { value: ['westeurope'] }
    }
  }
}

resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'dont-delete-me'
  properties: { level: 'CanNotDelete' }
}
```

### Lab 3 — Tags, budgets, management groups

- Tag `rg-az104-identity` with `env=lab`, `owner=<you>` via Portal, then bulk-apply the same tag with `az tag update` or `Update-AzTag`, then define the same tags as a Bicep `tags` property on a resource group deployment (subscription-scope deployment).
- Cost Management → Budgets → create a €10 monthly budget with an alert at 80% on your subscription.
- Management groups → create one (`mg-az104-lab`) and move your subscription under it, just to see the hierarchy in the Portal — this is usually enterprise-admin territory but worth seeing once.

## Design-scenario challenge

Your company wants: contractors get read-only access to a single resource group for 90 days, full-time engineers get Contributor scoped to their team's resource group, and no one — regardless of role — can deploy resources outside `westeurope` or delete a resource group tagged `env=prod` without going through a break-glass process. Sketch the RBAC assignments, the Policy definitions, and the locks you'd use, and note which of the three (RBAC, Policy, Lock) each requirement maps to.

## Exam checklist

- [ ] Create/manage Entra users, groups, licenses, external (guest) users
- [ ] Configure self-service password reset (SSPR)
- [ ] Assign built-in roles at management group / subscription / RG / resource scope
- [ ] Interpret effective access (multiple role assignments, deny assignments)
- [ ] Create and assign Azure Policy definitions/initiatives
- [ ] Configure resource locks (CanNotDelete, ReadOnly)
- [ ] Apply/manage tags (including bulk and inheritance via Policy)
- [ ] Manage resource groups and subscriptions (move resources, cost views)
- [ ] Configure budgets, cost alerts, Azure Advisor cost recommendations
- [ ] Configure management groups and understand inheritance

## Gaps / review-later list
*(fill in as you go — anything that felt shaky during labs)*
