# Domain 2 — Implement and Manage Storage (15–20%)

## Concepts

A **storage account** is the top-level container (namespace) for blobs, files, queues, and tables. Three axes define almost every exam question here: **access control** (network firewall rules, SAS tokens, access keys, Entra-based identity access), **redundancy** (LRS/ZRS/GRS/GZRS — how many copies, in how many places), and **data lifecycle** (tiers: Hot/Cool/Cold/Archive, plus lifecycle management rules that auto-move or delete blobs by age). Blob storage and Azure Files solve different problems — Blob is object storage for apps/backups/static content, Files is an SMB/NFS share you can literally mount as a network drive — but the exam tests both under one domain because the account-level concepts (access, redundancy, encryption) apply identically to both.

## Why it matters on the job

Storage misconfiguration is one of the most common real-world cloud incidents — public blob containers leaking data, missing lifecycle rules causing runaway storage cost, SAS tokens with no expiry sitting in code. Understanding *why* you'd choose a stored access policy over a raw SAS token, or object replication over just GRS, is the difference between passing a question and being trusted to design a storage architecture at work.

## Hands-on labs

### Lab 1 — Create and configure a storage account

**Portal:** Storage accounts → Create → in `rg-az104-storage`, name `stalabpatrick<random>`, choose Standard/LRS to start, enable "secure transfer required." After creation: Configuration blade → change redundancy to GRS and observe the extra cost/behavior notes; Encryption blade → note the default Microsoft-managed keys.

**CLI / PowerShell:**
```bash
az group create -n rg-az104-storage -l westeurope
az storage account create -n stalabpatrickXX -g rg-az104-storage -l westeurope --sku Standard_LRS --https-only true
az storage account update -n stalabpatrickXX -g rg-az104-storage --sku Standard_GRS
```
```powershell
New-AzStorageAccount -ResourceGroupName rg-az104-storage -Name stalabpatrickXX -Location westeurope -SkuName Standard_LRS -EnableHttpsTrafficOnly $true
Set-AzStorageAccount -ResourceGroupName rg-az104-storage -Name stalabpatrickXX -SkuName Standard_GRS
```

**Bicep:**
```bicep
param storageAccountName string = 'stalabpatrick${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: { name: 'Standard_GRS' }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}
output accountName string = storageAccount.name
```

### Lab 2 — Containers, blobs, tiers, lifecycle, soft delete

- Portal: create a container `demo`, upload a file, set its access tier to Cool manually, then enable **soft delete** for blobs (7 days) and **blob versioning** at the storage account level. Delete the blob, then recover it from the "Show deleted blobs" toggle.
- CLI: `az storage container create`, `az storage blob upload`, `az storage blob set-tier --tier Cool`.
- Bicep — add a lifecycle management policy that moves blobs to Cool after 30 days and deletes after 365:
```bicep
resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    policy: {
      rules: [
        {
          name: 'move-and-expire'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: { blobTypes: ['blockBlob'] }
            actions: {
              baseBlob: {
                tierToCool: { daysAfterModificationGreaterThan: 30 }
                delete: { daysAfterModificationGreaterThan: 365 }
              }
            }
          }
        }
      ]
    }
  }
}
```

### Lab 3 — Access: SAS tokens, stored access policies, network rules, Azure Files

- Generate an ad-hoc SAS token in the Portal (Shared access signature blade), note expiry/permissions. Then generate one via CLI with `az storage container generate-sas`, and via PowerShell with `New-AzStorageContainerSASToken`.
- Create a **stored access policy** on a container (revocable, unlike a raw SAS) and issue a SAS against that policy — this is the exam's favorite "why would you use this over a plain SAS" scenario (instant revocation without rotating keys).
- Storage account → Networking → restrict to "Selected networks," add your own IP as an allowed range, confirm access from browser breaks/works accordingly.
- Create an Azure Files share, mount it (Portal gives you the exact `net use` / `mount` command for your OS), and separately configure **identity-based access** (Entra Domain Services or on-prem AD DS integration) — for the exam, just know it exists and what it replaces (storage account key auth for SMB).

## Design-scenario challenge

An app team needs read-only, time-boxed access (72 hours) to a specific container for an external auditor, must be revocable instantly if the audit is cancelled early, and the storage account must reject all traffic except from the company's two office IP ranges and one Azure VNet. Design the access mechanism (SAS type, network config) and justify each choice against the alternatives.

## Exam checklist

- [ ] Configure storage firewalls / VNet rules
- [ ] Create and use SAS tokens; configure stored access policies
- [ ] Manage storage account access keys (rotate, regenerate)
- [ ] Configure identity-based access for Azure Files
- [ ] Create/configure storage accounts; redundancy (LRS/ZRS/GRS/GZRS)
- [ ] Configure object replication
- [ ] Configure encryption (Microsoft-managed vs customer-managed keys)
- [ ] Use Azure Storage Explorer and AzCopy for data movement
- [ ] Create/configure Azure Files shares and Blob containers
- [ ] Configure storage tiers (Hot/Cool/Cold/Archive)
- [ ] Configure soft delete for blobs/containers and for Azure Files snapshots
- [ ] Configure blob lifecycle management rules
- [ ] Configure blob versioning

## Gaps / review-later list
*(fill in as you go)*
