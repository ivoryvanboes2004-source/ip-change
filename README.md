# Change Static IP - Ubuntu (Netplan)

This script:

- Auto-detects your current network settings (interface, IP, subnet, gateway, DNS)
- Shows them as defaults — just press Enter to keep a value
- Asks for confirmation before applying
- Makes a backup of your current netplan config
- Automatically restores backup on failure

> ⚠️ **WARNING**  
> This will overwrite your current netplan config.  
> Only run this if you know what you're doing.

---

## What it does

1. Detects current interface, IP, gateway and DNS automatically
2. Lets you enter new values (press Enter to keep current)
3. Shows a summary and asks for confirmation
4. Makes a backup of your current netplan config
5. Writes the new config and runs `netplan apply`
6. Restores backup automatically if something goes wrong

---

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/ivoryvanboes2004-source/ip-change/refs/heads/main/ip-change.sh -o ip-change.sh
chmod +x ip-change.sh
sudo ./ip-change.sh
```

---

## Example

```
── Huidige instellingen ─────────────────────────
  Interface : ens18
  IP adres  : 192.168.1.50
  Subnet    : 24
  Gateway   : 192.168.1.1
  DNS 1     : 8.8.8.8
  DNS 2     : 1.1.1.1
─────────────────────────────────────────────────

Druk op Enter om de huidige waarde te behouden.

Interface  [ens18]:
IP adres   [192.168.1.50]: 192.168.1.100
Subnet     [24]:
Gateway    [192.168.1.1]:
DNS 1      [8.8.8.8]:
DNS 2      [1.1.1.1]:
```
