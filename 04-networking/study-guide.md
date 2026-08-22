# Domain 4 — Implement and Manage Virtual Networking (15–20%)

## Concepts

A **Virtual Network (VNet)** is your private address space in Azure, carved into **subnets**. Traffic control happens at two layers you must keep separate: **Network Security Groups (NSGs)** filter traffic by IP/port/protocol at the subnet or NIC level (a firewall), while **routing** (system routes plus **user-defined routes**) determines *where* traffic goes next (a router). **Peering** connects VNets to each other privately; **service endpoints** and **private endpoints** connect VNets privately to PaaS services (Storage, SQL, etc.) — private endpoints give the PaaS resource an actual private IP in your VNet, service endpoints just optimize/secure the route over the Microsoft backbone without changing the PaaS resource's public identity. **Azure DNS** resolves names; **load balancers** (Standard SKU, public or internal) distribute traffic across backend pools; **Azure Bastion** gives you browser-based RDP/SSH without exposing a public IP on the VM — this single service answers a huge share of "how do I securely access a VM" exam questions.

## Why it matters on the job

Networking is where most "it works on my machine but not in Azure" tickets live, and it's the domain enterprise IT ops teams touch daily — NSG rule troubleshooting, DNS resolution issues, VPN/peering connectivity. It's also the domain where a wrong answer has the highest blast radius (a bad NSG or route can silently take down connectivity for an entire subnet), so the exam leans hard on troubleshooting scenarios here, not just creation.

## Hands-on labs

### Lab 1 — VNets, subnets, peering

**Portal:** Create two VNets, `vnet-hub` (10.0.0.0/16) and `vnet-spoke` (10.1.0.0/16), each with one subnet. Peer them (bidirectional, in both VNets' Peerings blades) and confirm each shows "Connected." Deploy one VM in each and test connectivity (ping/SSH across the peering) once NSGs allow it.

**CLI:**
```bash
az network vnet create -g rg-az104-net -n vnet-hub --address-prefix 10.0.0.0/16 --subnet-name default --subnet-prefix 10.0.0.0/24
az network vnet create -g rg-az104-net -n vnet-spoke --address-prefix 10.1.0.0/16 --subnet-name default --subnet-prefix 10.1.0.0/24
az network vnet peering create -g rg-az104-net -n hub-to-spoke --vnet-name vnet-hub --remote-vnet vnet-spoke --allow-vnet-access
az network vnet peering create -g rg-az104-net -n spoke-to-hub --vnet-name vnet-spoke --remote-vnet vnet-hub --allow-vnet-access
```

**Bicep** — this is a great one to template since hub/spoke is a real-world pattern:
```bicep
resource hub 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-hub'
  location: resourceGroup().location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [{ name: 'default', properties: { addressPrefix: '10.0.0.0/24' } }]
  }
}
resource spoke 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-spoke'
  location: resourceGroup().location
  properties: {
    addressSpace: { addressPrefixes: ['10.1.0.0/16'] }
    subnets: [{ name: 'default', properties: { addressPrefix: '10.1.0.0/24' } }]
  }
}
resource peer1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: hub
  name: 'hub-to-spoke'
  properties: { remoteVirtualNetwork: { id: spoke.id }, allowVirtualNetworkAccess: true }
}
resource peer2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: spoke
  name: 'spoke-to-hub'
  properties: { remoteVirtualNetwork: { id: hub.id }, allowVirtualNetworkAccess: true }
}
```

### Lab 2 — NSGs, application security groups, effective rules

- Create an NSG, add a rule denying inbound RDP/SSH from the internet (should already be default) and one allowing it only from your own public IP. Associate it to the spoke subnet.
- Create two Application Security Groups (`asg-web`, `asg-db`), assign VMs' NICs to them, then write an NSG rule using the ASGs as source/destination instead of IP ranges — this is the pattern that scales in real environments.
- Portal → NSG → **Effective security rules** on a NIC — use this to see the merged result of subnet + NIC level NSGs plus Azure's default rules. This exact blade is what the exam calls "evaluate effective security rules."

### Lab 3 — Bastion, service/private endpoints, routing

- Deploy Azure Bastion into a VNet (needs its own `AzureBastionSubnet`, /26 minimum) and connect to a VM through the Portal with no public IP on the VM at all.
- Create a storage account, then add a **private endpoint** for blob storage into your VNet; confirm DNS now resolves the storage account's public hostname to a private 10.x address from inside the VNet. Separately, on another subnet, enable a **service endpoint** for `Microsoft.Storage` and compare: the storage account's public IP restriction list now shows the VNet/subnet as an option.
- Create a route table with a user-defined route sending 0.0.0.0/0 to a virtual appliance/firewall's IP (simulate — you don't need a real firewall), associate it to a subnet, and use Network Watcher's **Next Hop** tool to confirm the route is applied.

### Lab 4 — DNS and load balancing

- Azure DNS: create a public DNS zone, add an A record and a CNAME, and (if you own a test domain) delegate NS records — otherwise just verify resolution within Azure.
- Deploy a Standard **internal load balancer** in front of two VMs in the spoke VNet, with a health probe on port 80, and a public load balancer variant for comparison. Use Network Watcher's **Connection Troubleshoot** to test connectivity through it.

## Design-scenario challenge

You need a hub VNet with a Bastion host and shared services, three spoke VNets (dev/test/prod) each isolated from each other but able to reach the hub, and prod's database subnet must be reachable *only* from the app subnet in the same VNet — nothing else, not even other prod subnets. Sketch the peering topology, NSG placement, and note where you'd use a route table versus an NSG to enforce isolation.

## Exam checklist

- [ ] Create/configure VNets and subnets
- [ ] Create/configure VNet peering
- [ ] Configure public IP addresses
- [ ] Configure user-defined routes
- [ ] Troubleshoot network connectivity (Network Watcher tools)
- [ ] Create/configure NSGs and application security groups
- [ ] Evaluate effective security rules
- [ ] Implement Azure Bastion
- [ ] Configure service endpoints for PaaS
- [ ] Configure private endpoints for PaaS
- [ ] Configure Azure DNS (public/private zones, records)
- [ ] Configure internal and public load balancers
- [ ] Troubleshoot load balancing

## Gaps / review-later list
*(fill in as you go)*
