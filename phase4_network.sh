#!/bin/bash
# ═══════════════════════════════════════════════════════
# NexusOS — Phase 4 : Réseau haute performance
# ═══════════════════════════════════════════════════════

set -e
source /root/nexusos_vars.sh

echo "═══════════════════════════════════════"
echo "  NexusOS — Phase 4 : Réseau"
echo "═══════════════════════════════════════"

# TCP BBR
echo "[1/4] Configuration TCP BBR..."
cat > /etc/sysctl.d/99-nexusos-network.conf << 'EOF'
# BBR gaming
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Buffers 128 Mo
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

# Latence réduite
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_nodelay = 1
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.ip_local_port_range = 1024 65535
EOF

# Drivers Xiaomi
echo "[2/4] Drivers Xiaomi..."
cat > /etc/modules-load.d/nexusos-xiaomi.conf << 'EOF'
mt7921u
mt7663s
mt7612u
mt7601u
r8152
ax88179_178a
btusb
btrtl
qmi_wwan
cdc_mbim
EOF

cat > /etc/modprobe.d/nexusos-network.conf << 'EOF'
options btusb enable_autosuspend=0
options r8169 use_dac=1
EOF

# DNS Cloudflare gaming
echo "[3/4] Configuration DNS..."
cat > /etc/systemd/resolved.conf << 'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1
DNSOverTLS=yes
DNSSEC=yes
Cache=yes
EOF

# NetSwitch — daemon Python sélection auto réseau
echo "[4/4] Installation NetSwitch..."
cat > /usr/local/bin/nexus-netswitch << 'PYEOF'
#!/usr/bin/env python3
"""NexusOS NetSwitch — Sélection automatique meilleure connexion"""
import subprocess, time, logging

logging.basicConfig(
    filename='/var/log/nexusos-network.log',
    level=logging.INFO,
    format='%(asctime)s %(message)s'
)

INTERFACES = [
    ("eth0",   1, "Ethernet"),
    ("wlan0",  2, "WiFi 6"),
    ("wlan1",  3, "WiFi 5GHz"),
    ("wwan0",  4, "4G/5G"),
]

def ping_latency(iface):
    try:
        result = subprocess.run(
            ["ping", "-I", iface, "-c", "3", "-W", "1", "1.1.1.1"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            lines = result.stdout.split("\n")
            for line in lines:
                if "avg" in line:
                    return float(line.split("/")[4])
    except: pass
    return 9999

def set_default_route(iface):
    try:
        subprocess.run(["ip", "route", "del", "default"], capture_output=True)
        subprocess.run(["ip", "route", "add", "default", "dev", iface], check=True)
        logging.info(f"Route par défaut → {iface}")
    except: pass

current = None
while True:
    best_iface = None
    best_latency = 9999
    for iface, prio, name in INTERFACES:
        lat = ping_latency(iface)
        if lat < best_latency:
            best_latency = lat
            best_iface = iface
    if best_iface and best_iface != current:
        set_default_route(best_iface)
        current = best_iface
        logging.info(f"Bascule vers {best_iface} ({best_latency:.1f} ms)")
    time.sleep(30)
PYEOF

chmod +x /usr/local/bin/nexus-netswitch

cat > /etc/systemd/system/nexus-netswitch.service << 'EOF'
[Unit]
Description=NexusOS NetSwitch — Auto réseau
After=network.target

[Service]
ExecStart=/usr/local/bin/nexus-netswitch
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl enable nexus-netswitch

echo ""
echo "✓ Phase 4 terminée — Lancement phase 5..."
bash /root/phase5_desktop.sh
