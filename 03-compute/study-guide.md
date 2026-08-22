# Domain 3 — Deploy and Manage Azure Compute Resources (20–25%)

## Concepts

This is the heaviest-weighted domain and covers four compute models that all show up on real architecture diagrams: **IaaS** (VMs — full OS control), **VM Scale Sets** (autoscaling groups of identical VMs), **containers** (Container Instances for simple/serverless containers, Container Apps for microservices-style workloads, Container Registry to store images), and **App Service** (PaaS — you deploy code/containers, Azure manages the OS/runtime). The exam also folds in **ARM templates and Bicep** here, since deployment automation is treated as a compute-management skill. Bicep compiles down to ARM JSON — think of it as the human-friendly authoring layer over the same deployment engine.

## Why it matters on the job

Choosing the right compute model (VM vs. Container App vs. App Service) is one of the highest-value architectural decisions you'll be asked to make or review, because it drives cost, operational burden, and scalability. And since your goal is IaC/platform engineering specifically, this is the domain where Bicep transitions from "exam requirement" to "the actual tool you'll use daily" — deploying compute is the most common IaC task in any Azure shop.

## Hands-on labs

### Lab 1 — ARM/Bicep fundamentals (do this first, before the VM labs)

- Export an existing resource group as an ARM template (Portal → Resource group → Export template) and read through the JSON — painful on purpose, so Bicep's value is obvious.
- Convert it: `az bicep decompile --file exported-template.json`.
- Modify the decompiled Bicep (change a SKU or add a tag) and redeploy with `az deployment group create --template-file main.bicep --resource-group rg-az104-compute`.
- Understand **what-if**: `az deployment group what-if --template-file main.bicep --resource-group rg-az104-compute` — run this before every deploy from now on, it's a core safety habit.

### Lab 2 — Virtual machines

**Portal:** Create a Linux or Windows VM in `rg-az104-compute`, Standard_B1s size, with a new VNet. Afterward: Disks blade → add and attach a data disk; Size blade → resize to a different SKU (note it requires a restart); enable **encryption at host** under the Advanced/Security tab (may require a subscription feature registration first).

**CLI/PowerShell:**
```bash
az vm create --resource-group rg-az104-compute --name vm-az104-01 --image Ubuntu2204 --size Standard_B1s --admin-username azureuser --generate-ssh-keys
az vm disk attach --resource-group rg-az104-compute --vm-name vm-az104-01 --name datadisk01 --new --size-gb 32
az vm resize --resource-group rg-az104-compute --name vm-az104-01 --size Standard_B2s
az vm update --resource-group rg-az104-compute --name vm-az104-01 --set securityProfile.encryptionAtHost=true
```

**Bicep** — build the VM as code, including the data disk:
```bicep
param adminUsername string
@secure()
param adminPassword string
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-az104'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.10.0.0/16'] }
    subnets: [{ name: 'default', properties: { addressPrefix: '10.10.0.0/24' } }]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: 'nic-vm-az104-01'
  location: location
  properties: {
    ipConfigurations: [{
      name: 'ipconfig1'
      properties: { subnet: { id: vnet.properties.subnets[0].id } }
    }]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'vm-az104-01'
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_B1s' }
    osProfile: {
      computerName: 'vmaz10401'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical', offer: '0001-com-ubuntu-server-jammy', sku: '22_04-lts', version: 'latest'
      }
      osDisk: { createOption: 'FromImage' }
      dataDisks: [{
        lun: 0, createOption: 'Empty', diskSizeGB: 32
      }]
    }
    networkProfile: {
      networkInterfaces: [{ id: nic.id }]
    }
  }
}
```
Then move it: try `az resource move` to a different resource group and observe which resources come along (NIC/disk are separate resources you must move too — a very common exam trap).

### Lab 3 — Availability, scale sets

- Deploy a Virtual Machine Scale Set (Portal, then repeat via `az vmss create` and Bicep `Microsoft.Compute/virtualMachineScaleSets`), set min/max instance count and a CPU-based autoscale rule.
- Separately, understand (read, don't need to fully lab) the difference between **availability zones** (physically separate datacenters, protects against datacenter-level failure) and **availability sets** (fault/update domains within one datacenter, protects against rack/host failure) — deploy one VM into an availability set via CLI as a quick check: `az vm availability-set create` then `az vm create --availability-set ...`.

### Lab 4 — Containers

- Container Registry: `az acr create --sku Basic`, push a simple image (`az acr build` can build+push in one step from a local Dockerfile).
- Container Instances: `az container create --image <acr>.azurecr.io/myapp:v1 --registry-login-server ...` — fastest way to run one container with no orchestration.
- Container Apps: create a Container Apps environment and deploy the same image, then configure scaling rules (min/max replicas, HTTP-based scale rule) — this is the modern default for microservices on Azure and worth extra lab time versus Container Instances.

### Lab 5 — App Service

- Create an App Service Plan (Portal), then a Web App on it. Configure a custom domain + free managed certificate, deployment slots (`staging` + swap to production), and a backup schedule to a storage account.
- CLI: `az appservice plan create`, `az webapp create`, `az webapp deployment slot create`, `az webapp deployment slot swap`.
- Bicep: define `Microsoft.Web/serverfarms` + `Microsoft.Web/sites` + a slot as a child resource — this is a very common real-world Bicep module to have in your library.

## Design-scenario challenge

A team wants to run a stateless API that spikes hard during business hours and idles at night, needs zero-downtime deploys, and must not require them to patch an OS. Compare VM Scale Set, Container Apps, and App Service for this workload, pick one, and justify it including cost-shape reasoning (idle cost matters here).

## Exam checklist

- [ ] Interpret and modify ARM templates / Bicep files
- [ ] Deploy resources from ARM/Bicep; export/convert between them
- [ ] Create and configure VMs; encryption at host
- [ ] Move a VM across resource group / subscription / region
- [ ] Manage VM sizes and disks
- [ ] Deploy VMs to availability zones and availability sets
- [ ] Deploy/configure VM Scale Sets (including autoscale)
- [ ] Create/manage Azure Container Registry
- [ ] Provision containers via Container Instances and Container Apps
- [ ] Manage sizing/scaling for containers
- [ ] Provision an App Service plan; configure scaling
- [ ] Create an App Service; configure TLS/certificates, custom domain
- [ ] Configure App Service backup, networking settings, deployment slots

## Gaps / review-later list
*(fill in as you go)*
