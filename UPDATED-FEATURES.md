# Updated Features - SCADA Integration

## What's New

### 1. OpenPLC Runtime Integration
- Pre-configured OpenPLC container with reactor control program
- Modbus TCP server on port 502
- Web interface on port 8081

### 2. ScadaBR SCADA System
- Pre-configured ScadaBR HMI system
- Connected to OpenPLC via Modbus
- Web interface on port 8080

### 3. Dual Network Architecture
- **Mahashakti Network** (192.168.100.0/24): IEDs and GOOSE traffic
- **Aushadi Raksha Network** (192.168.200.0/24): OpenPLC and ScadaBR
- **Kali Workstation**: Connected to BOTH networks

### 4. Updated Management Scripts

All event management scripts have been updated:

#### ctf-admin.sh
- ✅ Shows OpenPLC and ScadaBR URLs on deployment
- ✅ Includes SCADA containers in stop/start operations
- ✅ Cleanup removes SCADA images
- ✅ System info displays SCADA images

#### status.sh
- ✅ Separate section for SCADA systems
- ✅ Shows OpenPLC and ScadaBR status
- ✅ Counts SCADA containers in summary

#### monitor.sh
- ✅ Real-time SCADA container monitoring
- ✅ Shows SCADA in container count
- ✅ Tracks SCADA system health

## File Structure

```
indra-ctf/
├── src/                          # IED source code
├── docker/                       # Dockerfiles
├── deployment/
│   └── docker-compose-ctf-final.yml  # Updated with SCADA
├── event-management/
│   ├── ctf-admin.sh             # ✅ Updated
│   ├── status.sh                # ✅ Updated
│   ├── monitor.sh               # ✅ Updated
│   ├── SCADA-INTEGRATION.md     # 🆕 New guide
│   └── ... (other scripts)
└── UPDATED-FEATURES.md          # This file
```

## Quick Start

### 1. Deploy Environment
```bash
cd deployment
docker-compose -f docker-compose-ctf-final.yml up -d
```

### 2. Check Status
```bash
cd ../event-management
./status.sh
```

Expected output:
```
=== CTF Environment Status ===
Time: ...

SCADA Systems:
NAMES     STATUS    PORTS
openplc   Up        0.0.0.0:8081->8080/tcp, 0.0.0.0:502->502/tcp
scadabr   Up        0.0.0.0:8080->8080/tcp

All Teams:
...

IED Containers:
...

Summary:
Teams: X / X containers
SCADA: 2 / 2 containers
```

### 3. Access Systems

**From Host:**
- Breaker v1: http://localhost:9001
- Breaker v2: http://localhost:9002
- OpenPLC: http://localhost:8081
- ScadaBR: http://localhost:8080/ScadaBR

**From Kali:**
```bash
docker exec -it kali-workstation bash

# Test Aushadi Raksha network (SCADA)
curl http://192.168.200.3:8080
curl http://192.168.200.4:8080

# Test Mahashakti network (IEDs)
curl http://192.168.100.4:9000
curl http://192.168.100.2:9000
```

## Network Verification

Verify Kali has dual network access:
```bash
docker exec kali-workstation ip addr show

# Should see:
# eth0: 192.168.100.5 (mahashakti)
# eth1: 192.168.200.2 (aushadi_raksha)
```

## Management Tool

Use the comprehensive admin tool:
```bash
cd event-management
./ctf-admin.sh
```

Menu options:
1. Installation & Setup
2. Deployment (includes SCADA)
3. Updates & Git
4. CTF Management
5. System Information (shows SCADA)
6. Team Access Details

## What Was Changed

### docker-compose-ctf-final.yml
- Added `openplc` service
- Added `scadabr` service
- Added `aushadi_raksha` network (192.168.200.0/24)
- Connected `kali-workstation` to both networks

### ctf-admin.sh
- Updated `deploy_ctf()` to show SCADA URLs
- Updated `stop_all()` to include SCADA containers
- Updated `start_all()` to include SCADA containers (with proper startup order)
- Updated `remove_all()` to include SCADA containers
- Updated `full_cleanup()` to remove SCADA images
- Updated `system_info()` to show SCADA images

### status.sh
- Added SCADA systems section
- Added SCADA container count
- Shows stopped SCADA containers

### monitor.sh
- Added SCADA container monitoring
- Shows SCADA in container status
- Tracks SCADA health

## Benefits

1. **More Realistic**: Mimics real industrial environments with SCADA/PLC systems
2. **Multiple Attack Vectors**: GOOSE + Modbus + HMI
3. **Network Segmentation**: Demonstrates OT network architecture
4. **Educational**: Shows integration of different industrial protocols
5. **Scalable**: Easy to add more SCADA systems or PLCs

## Next Steps

1. Test the deployment: `./ctf-admin.sh`
2. Verify all containers: `./status.sh`
3. Monitor live: `./monitor.sh`
4. Read SCADA integration guide: `SCADA-INTEGRATION.md`

## Support

For issues or questions:
1. Check logs: `docker logs openplc` or `docker logs scadabr`
2. Review `SCADA-INTEGRATION.md` for troubleshooting
3. Use `./ctf-admin.sh` for management tasks
