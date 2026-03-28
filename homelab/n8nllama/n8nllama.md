n8n + Ollama Homelab: Local AI Automation Stack

System Overview

Two VMs running on a single ESXi 8.0.3 host, communicating over Tailscale, each serving a distinct role in the stack:

VM	Role	Key Service	
llama-brain	LLM inference backend	Ollama	
n8n-node	Workflow automation frontend	n8n	


Host: ESXi 8.0.3

Networking decisions:


Configured a dedicated vSwitch for VM-to-VM traffic (no uplink, internal only)

vmkernel adapter assigned to the management network for ESXi host access

VMs on the internal vSwitch communicate without touching the physical switch


VM: llama-brain (Ollama)

Purpose

Serves as the isolated inference backend. Keeping LLM compute in its own VM means resource contention is predictable and the service can be restarted, snapshotted, or swapped without touching the automation layer.

Install path

# Install Ollama (Linux)
curl -fsSL https://ollama.com/install.sh | sh

# Pull a model
ollama pull llama3

# Verify service is listening
ss -tlnp | grep 11434


Ollama binds to localhost:11434 by default. Since n8n lives in a different VM, the service needs to be reachable over the network — either the internal vSwitch or Tailscale.

Making Ollama reachable across VMs

By default, Ollama only listens on loopback. To expose it on all interfaces:

# /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=0.0.0.0"


systemctl daemon-reload
systemctl restart ollama


Then confirm with:

curl http://<llama-brain-ip>:11434/api/tags


Security note: Binding to 0.0.0.0 with no auth on a private/internal vSwitch is acceptable. This would not be acceptable on an internet-facing interface. Tailscale handles the perimeter.


VM: n8n-node (n8n)

Purpose

Workflow automation engine. Triggers, conditions, HTTP requests, and integrations live here. Connects to llama-brain over the network to hit the Ollama API.

Install path (Docker approach)

docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n


Or as a systemd service if running bare-metal on the VM without Docker.

Connecting n8n to Ollama

In n8n, the Ollama node (or HTTP Request node targeting the API directly) needs the inference VM's address:

http://<llama-brain-tailscale-ip>:11434


Using Tailscale IPs here rather than local vSwitch IPs keeps things consistent whether accessing remotely or locally, and avoids hardcoding RFC 1918 addresses that could shift.

Ollama API endpoint used by n8n:

POST /api/generate
{
  "model": "llama3",
  "prompt": "...",
  "stream": false
}



Overlay Network: Tailscale

Tailscale creates a WireGuard-based mesh between devices, assigned stable 100.x.x.x addresses regardless of LAN topology.

Why Tailscale instead of just using the local vSwitch?


Remote access from anywhere without port forwarding or VPN server setup

Stable addressing — Tailscale IPs don't change even if DHCP reassigns local IPs

n8n webhooks can be triggered from outside the home network

Future-proofing: if VMs move hosts, the Tailscale addresses stay the same


Setup on each VM

curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up


Both VMs authenticate to the same Tailscale account, putting them on the same tailnet. They can reach each other at 100.x.x.x addresses.

DuckDNS

DuckDNS maps a subdomain to the Tailscale IP of the n8n VM, giving a stable human-readable address for the n8n UI and webhooks. Updated via a simple cron job or the DuckDNS update script:

# cron: update DuckDNS every 5 minutes
*/5 * * * * curl -s "https://www.duckdns.org/update?domains=YOUR_DOMAIN&amp;token=YOUR_TOKEN&amp;ip=" &gt; /dev/null



Service Communication Flow

External trigger (webhook / manual)
        │
        ▼
   [n8n-node]  :5678
        │
        │  HTTP POST to Ollama API
        ▼
  [llama-brain] :11434
        │
        │  JSON response (generated text)
        ▼
   [n8n-node]
        │
        ▼
  Output action (log / webhook / etc.)


All inter-VM traffic goes over Tailscale. n8n acts as the orchestrator; Ollama is a stateless inference API that n8n calls on demand.


Operational Notes

Resource behavior (CPU-only inference)


llama3 8B on i5-9500: roughly 10–20s per response depending on prompt length

CPU usage spikes to ~90–100% across all 6 cores during generation

n8n workflow timeouts need to be set generously (60s+) to avoid premature failures


Snapshotting strategy


Snapshot llama-brain after a stable Ollama install + model pull (models are large, re-pulling is slow)

Snapshot n8n-node after working workflow configurations


Logs

# Ollama logs
journalctl -u ollama -f

# n8n logs (Docker)
docker logs -f n8n



What I Learned


vSwitch design — internal vSwitches with no uplink for VM-to-VM traffic; the tradeoff between isolation and manageability

Service binding — the difference between localhost, a specific IP, and 0.0.0.0, and when each is appropriate

Overlay networking — why Tailscale (WireGuard mesh) is operationally simpler than port forwarding or self-hosted VPN for a homelab; stable addressing as a feature

Systemd service overrides — using drop-in override files instead of editing the original unit file directly

API-first thinking — treating Ollama as a dumb HTTP API that any service can call; the value of separating compute from orchestration

