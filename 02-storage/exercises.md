# Today's Focus: Storage — Files & Security (Roadmap Week 6)

Roadmap row: *Azure Files, Azure File Sync, SAS tokens, access keys, lifecycle management, Storage Explorer & AzCopy* (8 target hrs).
Session 1: 2026-11-04, 4 hours. Session 2 (later this week): build the mini project.

This is a **workbook**: each exercise gives you an objective and a hint, not the finished command. Try it yourself first using the Portal and `az --help`. Reference commands are in the **Solutions & Verification** section at the bottom, and every concept links to the Microsoft Learn page it came from. Check them (that's the *Discernment* part of the AI Fluency 4D framework).

## Gap check: roadmap vs official exam objectives

The official AZ-104 skills outline ([study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104)) covers these, but the Week 6 roadmap row doesn't. They're added to this workbook:

- Stored access policies
- Azure Storage firewalls and virtual networks
- Identity-based access for Azure Files
- Snapshots and soft delete for Azure Files
- Storage account encryption

## Session plan (4 h)

| # | Block | Time | Status |
|---|---|---|---|
| 1 | Access keys, SAS, stored access policies | 60 min | ⏳ |
| 2 | Storage firewalls, virtual networks, encryption | 40 min | ⬜ |
| 3 | Azure Files: shares, snapshots, soft delete, identity-based access | 60 min | ⬜ |
| 4 | File Sync, Storage Explorer, AzCopy, lifecycle management | 40 min | ⬜ |
| 5 | Mini project design | 30 min | ⬜ |

---

## Block 1 — Access keys, SAS, stored access policies

### Core concepts

**Access keys** ([Learn](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-keys-manage))
- Every account gets two 512-bit keys, and each one gives **full access** to all data.
- Two keys exist so you can rotate without downtime. Point apps at key2, regenerate key1, point them back to key1, then regenerate key2. Microsoft advises using only one key across all apps at a time.
- Rotating a key **revokes every account SAS and service SAS signed with it**. A user delegation SAS isn't affected.
- Reading keys requires `Microsoft.Storage/storageAccounts/listkeys/action`. Owner, Contributor and Storage Account Key Operator Service Role all have it. **So a Contributor can read the keys and, through them, all the data.**
- A key expiration policy (`--key-exp-days`) sets a rotation reminder. The built-in Azure Policy *"Storage account keys should not be expired"* reports accounts that missed rotation.
- Microsoft recommends Entra ID with managed identities, and disabling Shared Key when it isn't needed ([Learn](https://learn.microsoft.com/azure/storage/common/shared-key-authorization-prevent)). If you want Conditional Access to protect a storage account, Shared Key must be disallowed.

**SAS types** ([Learn](https://learn.microsoft.com/en-us/azure/storage/common/storage-sas-overview))

| Type | Signed with | Scope | Stored access policy? |
|---|---|---|---|
| User delegation (recommended) | Entra ID (user delegation key) | Blob, Queue, Table, Files | ❌ |
| Service | Account key | One service | ✅ |
| Account | Account key | One or more services, including service-level operations | ❌ |

- A stored access policy sits on a container, share, queue or table. **Max 5 per container.** Delete or change it and every SAS linked to it is revoked, without rotating keys.
- A user delegation SAS lasts **at most 7 days**. `az storage account revoke-delegation-keys` revokes them all. The revocation may take effect with a delay, because keys and role assignments are cached ([Learn](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-user-delegation-sas-create-cli)).
- **Azure doesn't track SAS tokens.** You can't count or audit the ones that have been generated.
- **Clock skew:** set the start time at least 15 minutes in the past, or leave it empty.
- Copying blob ↔ file **always** requires a SAS, even inside the same account.

### Exercises (Block 1)

> Cost note: one Standard_LRS account with a few KB of data costs next to nothing. Delete the resource group at the end of the week.

**1.1 — Lab account.** Create `rg-az104-files` in West Europe with a StorageV2 Standard_LRS account (HTTPS-only, TLS 1.2) and a container called `audit`. Upload a small text file.
*Hint:* reuse Lab 1 from `study-guide.md` and change the names.

**1.2 — Key hygiene.** Check `keyCreationTime`, rotate both keys in the correct order, then set a 60-day key expiration policy and verify it.
*Hint:* the policy can't be created while `keyCreationTime` is null.

**1.3 — Ad hoc service SAS.** Generate a read+list SAS on `audit` that expires in 30 minutes, signed with the key. Use it to list the blobs without being signed in. Then rotate key1 and run the list again. What happens?

**1.4 — Stored access policy.** Create a stored access policy `auditor-ro` (read+list, 30 days) on `audit` and issue a SAS that references it. Confirm the SAS works, then delete the policy and run it again.
*Think:* how is this different from 1.3 when it comes to revoking access?

**1.5 — User delegation SAS.** Give yourself *Storage Blob Data Contributor* on the account, then generate a user delegation SAS for `audit` with `--auth-mode login --as-user`.
- Try setting an expiry 10 days out. What do the docs say actually happens?
- Revoke the user delegation keys.

**1.6 — Kill Shared Key.** Set *Allow storage account key access* to **Disabled**. Re-run a key-authorized command and note the error, then try exercise 1.4 again.
*Think:* what does this tell you about stored access policies on an account with Shared Key disabled?
**Turn Shared Key back on afterwards**, because Block 3 mounts a share with the key.

### Block 1 — answers to the scenario questions
*(filled in after we review your answers)*

---

## Block 2 — Storage firewalls, virtual networks, encryption
*(added during the session)*

## Block 3 — Azure Files
*(added during the session)*

## Block 4 — File Sync, Storage Explorer, AzCopy, lifecycle management
*(added during the session)*

## Block 5 — Mini project design
*(added during the session)*

---

## Solutions & Verification

> Variables used below (Cloud Shell, Bash):
> ```bash
> RG=rg-az104-files; LOC=westeurope; SA=stfilespatrick$RANDOM; C=audit
> ```

**1.1**
```bash
az group create -n $RG -l $LOC
az storage account create -n $SA -g $RG -l $LOC --sku Standard_LRS --kind StorageV2 --https-only true --min-tls-version TLS1_2
az storage container create --account-name $SA -n $C --auth-mode login   # requires a Storage Blob Data role, see 1.5
echo "hello auditor" > report.txt
az storage blob upload --account-name $SA -c $C -f report.txt -n report.txt --auth-mode login
```
*If `--auth-mode login` returns 403, you don't have a data-plane role yet. Do the role assignment from 1.5 first, or use `--auth-mode key` for now.*

**1.2** ([Learn: manage access keys](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-keys-manage))
```bash
az storage account show -n $SA -g $RG --query keyCreationTime
az storage account keys renew -g $RG --account-name $SA --key primary
az storage account keys renew -g $RG --account-name $SA --key secondary
az storage account update -n $SA -g $RG --key-exp-days 60
az storage account show -n $SA -g $RG --query "{KeyPolicy:keyPolicy}"
```

**1.3**
```bash
EXP=$(date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ')
SAS=$(az storage container generate-sas --account-name $SA -n $C --permissions rl --expiry $EXP --https-only --auth-mode key -o tsv)
az storage blob list --account-name $SA -c $C --sas-token "$SAS" -o table
az storage account keys renew -g $RG --account-name $SA --key primary
az storage blob list --account-name $SA -c $C --sas-token "$SAS" -o table   # expect auth failure (403)
```
*Why:* the SAS was signed with key1, and regenerating key1 invalidates every account or service SAS signed with it.

**1.4** ([Learn sample](https://learn.microsoft.com/azure/hdinsight/hdinsight-storage-sharedaccesssignature-permissions#create-a-stored-policy-and-sas))
```bash
POLEXP=$(date -u -d "30 days" '+%Y-%m-%dT%H:%MZ')
az storage container policy create --account-name $SA --container-name $C --name auditor-ro --permissions rl --expiry $POLEXP --auth-mode key
az storage container policy list   --account-name $SA --container-name $C --auth-mode key
PSAS=$(az storage container generate-sas --account-name $SA -n $C --policy-name auditor-ro --auth-mode key -o tsv)
az storage blob list --account-name $SA -c $C --sas-token "$PSAS" -o table
az storage container policy delete --account-name $SA --container-name $C --name auditor-ro --auth-mode key
az storage blob list --account-name $SA -c $C --sas-token "$PSAS" -o table   # access revoked; may take a short while
```

**1.5** ([Learn: user delegation SAS with CLI](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-user-delegation-sas-create-cli))
```bash
SAID=$(az storage account show -n $SA -g $RG --query id -o tsv)
az role assignment create --role "Storage Blob Data Contributor" --assignee $(az ad signed-in-user show --query id -o tsv) --scope $SAID
UEXP=$(date -u -d "6 days" '+%Y-%m-%dT%H:%MZ')
UDSAS=$(az storage container generate-sas --account-name $SA -n $C --permissions rl --expiry $UEXP --auth-mode login --as-user -o tsv)
echo $UDSAS    # look for skoid / sktid / ske fields, which mark it as a user delegation SAS
az storage account revoke-delegation-keys -n $SA -g $RG
```
*10-day expiry:* the user delegation key is valid for at most 7 days, so the SAS stops working when the key expires, whatever expiry you set.

**1.6** ([Learn: prevent Shared Key](https://learn.microsoft.com/azure/storage/common/shared-key-authorization-prevent))
```bash
az storage account update -n $SA -g $RG --allow-shared-key-access false
az storage account show   -n $SA -g $RG --query allowSharedKeyAccess     # false
az storage container policy list --account-name $SA --container-name $C --auth-mode key   # 403: key-based auth not permitted
az storage account update -n $SA -g $RG --allow-shared-key-access true    # re-enable for Block 3
```
*Takeaways:*
- A stored access policy only works with a **service SAS**, and a service SAS is signed with the **account key**. Disabling Shared Key therefore removes the stored-access-policy pattern for blobs. This is a real design trade-off.
- Microsoft's .NET sample notes that the operation that creates the policy (Set Container ACL) isn't supported with Entra ID authorization. ([Learn](https://learn.microsoft.com/azure/storage/common/storage-stored-access-policy-define-dotnet))
- The role assignment from 1.5 can take a few minutes to propagate.

---

## Gaps / review-later list
*(fill in as you go)*
