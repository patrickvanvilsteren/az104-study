# Domain 5 — Monitor and Maintain Azure Resources (10–15%)

## Concepts

**Azure Monitor** is the umbrella platform: **metrics** are lightweight numeric time-series (CPU %, disk IOPS) good for near-real-time alerting; **logs** (sent to a **Log Analytics workspace**, queried with **KQL** — Kusto Query Language) are rich, queryable event/diagnostic data good for investigation and correlation. **Alert rules** watch either and fire **action groups** (email, SMS, webhook, Logic App, etc.) — knowing the difference between a metric alert and a log alert, and what an action group vs. an alert processing rule does, is a recurring exam pattern. For resilience: **Azure Backup** (via a **Recovery Services vault** or the newer **Backup vault**) protects data through scheduled, retained backups you restore *in place*; **Azure Site Recovery** protects entire VMs through *replication* to a secondary region so you can fail over and keep running elsewhere during a regional outage. Backup answers "I lost/corrupted data," Site Recovery answers "my whole region is down."

## Why it matters on the job

This domain is where you move from "I built infrastructure" to "I keep infrastructure alive and provable" — the operational half of the job. In enterprise IT you'll live in Azure Monitor and Log Analytics for incident response, and Backup/Site Recovery configuration is exactly the kind of resilience work that gets audited by security/compliance teams. It's also naturally where AI-agent and automation skills connect: alert-triggered remediation (your Intune remediation-script experience is the same pattern) is a direct extension of this domain.

## Hands-on labs

### Lab 1 — Metrics, Log Analytics, KQL, alerts

**Portal:** On a VM from Domain 3, open Monitor → Metrics, chart CPU % over the last hour. Create a Log Analytics workspace, enable **VM Insights** on the VM (installs the monitoring agent), and after data flows, run a KQL query in Logs, e.g.:
```kql
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
| order by TimeGenerated desc
```
Create an **action group** (email to yourself), then a **metric alert rule**: CPU % > 80 for 5 minutes → fire the action group. Trigger it artificially with a stress tool (`stress-ng` on Linux, or a simple CPU-burn loop) and confirm the email arrives.

**CLI:**
```bash
az monitor log-analytics workspace create -g rg-az104-monitor -n law-az104
az monitor action-group create -g rg-az104-monitor -n ag-email --short-name az104ag --email-receiver name=me email=you@example.com
az monitor metrics alert create -g rg-az104-monitor -n high-cpu --scopes <vm-resource-id> \
  --condition "avg Percentage CPU > 80" --window-size 5m --evaluation-frequency 1m \
  --action ag-email
```

**Bicep:**
```bicep
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-az104'
  location: resourceGroup().location
  properties: { sku: { name: 'PerGB2018' }, retentionInDays: 30 }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-email'
  location: 'global'
  properties: {
    groupShortName: 'az104ag'
    enabled: true
    emailReceivers: [{ name: 'me', emailAddress: 'you@example.com', useCommonAlertSchema: true }]
  }
}

param vmResourceId string
resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'high-cpu'
  location: 'global'
  properties: {
    severity: 3
    enabled: true
    scopes: [vmResourceId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [{
        name: 'HighCPU'
        metricName: 'Percentage CPU'
        operator: 'GreaterThan'
        threshold: 80
        timeAggregation: 'Average'
      }]
    }
    actions: [{ actionGroupId: actionGroup.id }]
  }
}
```

### Lab 2 — Network Watcher (ties back to Domain 4)

Enable Network Watcher (usually auto-enabled per region), run **Connection Monitor** between two VMs across your hub/spoke peering, and review the topology diagram it generates — good exam prep for "how do you continuously verify connectivity" questions.

### Lab 3 — Backup

**Portal:** Create a Recovery Services vault, back up a VM with the default policy, then customize the policy (daily backup, 30-day retention). Trigger an on-demand backup, then perform a **file-level restore** (mount the recovery point, browse files) and a full VM restore to a new resource — compare the two restore types.

**CLI:**
```bash
az backup vault create -g rg-az104-monitor -n rsv-az104 -l westeurope
az backup policy create -g rg-az104-monitor -v rsv-az104 --name daily-30d --policy '{...}' --backup-management-type AzureIaasVM
az backup protection enable-for-vm -g rg-az104-monitor -v rsv-az104 --vm vm-az104-01 --policy-name daily-30d
az backup protection backup-now -g rg-az104-monitor -v rsv-az104 --container-name vm-az104-01 --item-name vm-az104-01
```

**Bicep** (vault + policy):
```bicep
resource vault 'Microsoft.RecoveryServices/vaults@2023-06-01' = {
  name: 'rsv-az104'
  location: resourceGroup().location
  sku: { name: 'RS0', tier: 'Standard' }
  properties: {}
}
```
*(VM protection/enable-backup is typically done via CLI/PowerShell or the Portal after the vault exists — Bicep support for backup policies/items is limited, which is itself a useful exam/real-world nuance: know when IaC hands off to imperative tooling.)*

### Lab 4 — Site Recovery (config-only lab — don't run a real failover unless you're comfortable with the cost/complexity)

Walk through enabling Site Recovery on a VM to replicate to a second region in the Portal far enough to see: the replication policy, recovery plan creation, and the **test failover** option (non-disruptive, spins up an isolated copy) versus a real failover. Understand this is the answer whenever a scenario says "minimize downtime during a regional outage."

## Design-scenario challenge

Your production app runs on 3 VMs. Leadership wants: (1) alerting within 5 minutes if any VM's disk queue length spikes, (2) daily backups retained 60 days with the ability to restore a single file without restoring the whole VM, and (3) the ability to keep the app running within 15 minutes if the entire primary region goes down. Map each requirement to the specific Azure Monitor / Backup / Site Recovery feature that satisfies it.

## Exam checklist

- [ ] Interpret metrics in Azure Monitor
- [ ] Configure diagnostic/log settings
- [ ] Query and analyze logs (KQL) in Log Analytics
- [ ] Set up alert rules, action groups, alert processing rules
- [ ] Configure/interpret Monitor Insights (VM, Storage, Network)
- [ ] Use Network Watcher and Connection Monitor
- [ ] Create a Recovery Services vault and a Backup vault
- [ ] Create/configure a backup policy
- [ ] Perform backup and restore operations
- [ ] Configure Azure Site Recovery for Azure resources
- [ ] Perform a failover to a secondary region
- [ ] Configure/interpret backup reports and alerts

## Gaps / review-later list
*(fill in as you go)*
