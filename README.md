# Indraprastha Kingdom CTF - IEC 61850 GOOSE Protocol Challenge

Industrial control system security challenge focusing on IEC 61850 GOOSE protocol vulnerabilities in a power grid substation.

## Overview

Exploit vulnerabilities in the IEC 61850 GOOSE protocol to disable weapons manufacturing in Indraprastha Kingdom's Northern District by opening the circuit breaker.

**Flag**: `FLAG{IEC61850_GOOSE_PWNED}`

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Git with submodules support
- 8GB RAM minimum
- Ports available: 9001, 9002, 8080, 8081, 502

### Installation

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/pg-ot/ftc.git
cd ftc

# Pull required images
docker pull kalilinux/kali-rolling:latest
docker pull pavi0204/openplc-with-message:latest
docker pull pavi0204/scadabr-with-message:latest

# Deploy all services
cd deployment
docker-compose -f docker-compose-ctf-final.yml up -d

# Verify deployment
bash status.sh
```

## Access Points

### Web Interfaces
- **Breaker IED v1 (Vulnerable)**: http://localhost:9001
- **Breaker IED v2 (Secure)**: http://localhost:9002
- **OpenPLC Runtime**: http://localhost:8081
- **ScadaBR SCADA**: http://localhost:8080/ScadaBR

### Kali Workstation
```bash
# Access attack platform
docker exec -it kali-workstation bash

# Pre-installed tools: tcpdump, tshark, nmap, scapy, netcat, curl, wget
```

## Operations

### Control Breaker
```bash
cd deployment

# Send TRIP command (opens breaker)
bash trip.sh

# Send CLOSE command (closes breaker)
bash close.sh

# Check system status
bash status.sh
```

### Stop Environment
```bash
cd deployment
docker-compose -f docker-compose-ctf-final.yml down
```

## Network Architecture

### Mahashakti Network (192.168.100.0/24)
IEC 61850 GOOSE Protocol Network

| Device | IP | Description |
|--------|-----|-------------|
| breaker-ied-v1 | 192.168.100.4 | Vulnerable breaker (no sequence validation) |
| breaker-ied-v2 | 192.168.100.2 | Secure breaker (with stNum/sqNum validation) |
| control-ied | 192.168.100.3 | GOOSE publisher (legitimate commands) |
| kali-workstation | 192.168.100.5 | Attack platform |

### Aushadi Raksha Network (192.168.200.0/24)
SCADA/Modbus Network

| Device | IP | Description |
|--------|-----|-------------|
| openplc | 192.168.200.3:502 | Modbus TCP server |
| scadabr | 192.168.200.4:8080 | SCADA HMI |
| kali-workstation | 192.168.200.2 | Dual-homed access |

### GOOSE Protocol Details
- **Multicast MAC**: `01:0c:cd:01:00:01`
- **AppID**: `1000`
- **Dataset**: PTRC (Protection Trip) + CSWI (Switch Control)
- **GoCB Reference**: `CTRL_IED/PROT/LLN0$GO$gcbControl`

## Challenge Objective

1. **Reconnaissance**: Capture GOOSE multicast traffic on Mahashakti network
2. **Analysis**: Decode IEC 61850 GOOSE protocol structure
3. **Exploitation**: Craft replay attacks to trip the vulnerable breaker
4. **Victory**: Retrieve flag from breaker web interface when opened

### Attack Strategy
- Breaker v1 is vulnerable to replay attacks (no sequence validation)
- Breaker v2 validates stNum/sqNum and rejects replayed messages
- Use tcpdump/tshark to capture legitimate GOOSE traffic
- Replay captured TRIP commands to open breaker v1

## Project Structure

```
ftc/
├── src/
│   ├── libiec61850/          # IEC 61850 protocol library (submodule)
│   ├── breaker_ied_v1.c      # Vulnerable breaker implementation
│   ├── breaker_ied_v2.c      # Secure breaker implementation
│   ├── control_ied.c         # GOOSE publisher
│   ├── flag_server_v1.py     # Web interface for breaker v1
│   ├── flag_server_v2.py     # Web interface for breaker v2
│   └── Makefile
├── docker/
│   ├── Dockerfile.breaker-v1
│   ├── Dockerfile.breaker-v2
│   ├── Dockerfile.ied-simulator
│   └── Dockerfile.kali
├── deployment/
│   ├── docker-compose-ctf-final.yml
│   ├── trip.sh               # Send TRIP command
│   ├── close.sh              # Send CLOSE command
│   └── status.sh             # Check system status
└── event-management/         # Multi-team deployment scripts
```

## Docker Images

### Custom Built
- `deployment-breaker-ied-v1` - Vulnerable breaker
- `deployment-breaker-ied-v2` - Secure breaker
- `deployment-control-ied` - GOOSE publisher

### Golden Images (Docker Hub)
- `pavi0204/breaker-ied-v1:golden`
- `pavi0204/breaker-ied-v2:golden`
- `pavi0204/control-ied:golden`
- `pavi0204/openplc-with-message:golden`
- `pavi0204/scadabr-with-message:golden`

## Troubleshooting

### Windows Line Ending Issues
If containers fail with exit code 255:

```powershell
cd docker
$files = @('start-breaker-v1.sh', 'start-breaker-v2.sh')
foreach ($file in $files) {
    $content = Get-Content $file -Raw
    $content = $content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($file, $content, [System.Text.UTF8Encoding]::new($false))
}
```

Then rebuild: `docker-compose -f docker-compose-ctf-final.yml build`

### Container Not Starting
```bash
# Check logs
docker logs substation-breaker-v1
docker logs substation-control-ied

# Restart specific container
docker restart substation-breaker-v1
```

### Network Issues
```bash
# Verify network connectivity from Kali
docker exec kali-workstation ping -c 2 192.168.100.4
docker exec kali-workstation ping -c 2 192.168.200.3
```

## Cloud Deployment

For multi-team cloud deployment, see [CLOUD-DEPLOYMENT.md](CLOUD-DEPLOYMENT.md).

**Quick Deploy (5 teams):**
```bash
cd deployment
sudo bash deploy-cloud-hardened.sh 5
```

**Features:**
- Isolated networks per team
- Resource limits (CPU, memory, PIDs)
- Read-only filesystem for security
- SSH access to Kali workstations
- Nginx authentication per team

## Learning Objectives

- Understand IEC 61850 GOOSE protocol structure
- Identify vulnerabilities in industrial protocols
- Perform packet capture and analysis
- Execute replay attacks on ICS systems
- Recognize importance of sequence number validation

## Security Notes

- This is an educational environment - never attack real ICS systems
- All vulnerabilities are intentional for learning purposes
- Breaker v2 demonstrates proper security implementation
- Always follow responsible disclosure for real-world findings

## Credits

Built for industrial cybersecurity training and CTF competitions.

## License

Educational use only. See LICENSE file for details.
