# Arch Linux Dynamic Power Profile Manager

A lightweight power management and profile-switching suite designed for Intel laptops (specifically tested on 10th Gen HP hardware with strict firmware-level power constraints). This setup lets you instantly cycle between **Performance**, **Balanced**, and **Eco** modes to balance thermal limits, battery life, and developer workflow responsiveness.

---

## Features

* **3-Mode Profile Switching:** Cycle seamlessly via a single keybinding (Performance -> Balanced -> Eco).
* **Hardware-Level Enforcement:** Uses `intel-undervolt` to override firmware power limits (PL1/PL2) and apply safe voltage offsets.
* **Dynamic Governor & EPP Tuning:** Automatically shifts CPU energy performance preferences (`performance`, `balance_performance`, `power`) and scaling governors.
* **Desktop Notifications:** Instant visual feedback via `libnotify` (`notify-send`) upon switching modes.
* **Compositor Integration:** Native integration with the **Niri** compositor via `config.kdl`.

---

## Prerequisites

Ensure you have the required packages installed on your Arch Linux system:

```bash
sudo pacman -S intel-undervolt libnotify s-tui stress-ng

```

---

## Setup & Installation

### 1. Configure Undervolt Profile Templates

Create three distinct profile templates in `/etc/` to define your power limits and voltage offsets.

* **Performance (`/etc/intel-undervolt.perf`)**
```text
undervolt 0 'CPU' -100
undervolt 1 'GPU' -80
undervolt 2 'CPU Cache' -80
power package 0 15 25

```


* **Balanced (`/etc/intel-undervolt.bal`)**
```text
undervolt 0 'CPU' -100
undervolt 1 'GPU' -80
undervolt 2 'CPU Cache' -80
power package 0 10 15

```


* **Eco (`/etc/intel-undervolt.eco`)**
```text
undervolt 0 'CPU' -100
undervolt 1 'GPU' -80
undervolt 2 'CPU Cache' -80
power package 0 6 10

```



### 2. Set Up Passwordless Sudo Permissions

To allow the toggle script to apply hardware limits without triggering password prompts or locking files, create a sudoers drop-in configuration.

1. Create the rule file:
```bash
sudo nano /etc/sudoers.d/99-power-toggle

```


2. Paste the following rule (replace `rexec` with your actual username if different):
```text
rexec ALL=(ALL) NOPASSWD: /usr/bin/intel-undervolt, /usr/bin/tee, /usr/bin/cp, /usr/bin/powertop, /usr/bin/rfkill

```


3. Set the strict permissions required by `sudo`:
```bash
sudo chmod 440 /etc/sudoers.d/99-power-toggle

```



### 3. Add the Toggle Script

Place the following script at `~/toggle_power.sh`:

```bash
#!/bin/bash

STATE_FILE="/tmp/power_mode"

# Read current state (defaults to 0 if file does not exist)
CURRENT_MODE=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

# Cycle to next mode: 0 (PERF) -> 1 (BAL) -> 2 (ECO) -> 0
NEXT_MODE=$(( (CURRENT_MODE + 1) % 3 ))

case $NEXT_MODE in
    0) # --- PERFORMANCE ---
        sudo /usr/bin/cp /etc/intel-undervolt.perf /etc/intel-undervolt.conf
        GOV="performance"; EPP="performance"
        notify-send -a "Power Profile" -u normal -i battery-full "Mode: PERFORMANCE" "Limit: 15W/25W | High Performance"
        ;;
    1) # --- BALANCED ---
        sudo /usr/bin/cp /etc/intel-undervolt.bal /etc/intel-undervolt.conf
        GOV="powersave"; EPP="balance_performance"
        notify-send -a "Power Profile" -u normal -i battery "Mode: BALANCED" "Limit: 10W/15W | Snappy & Efficient"
        ;;
    2) # --- ECO ---
        sudo /usr/bin/cp /etc/intel-undervolt.eco /etc/intel-undervolt.conf
        GOV="powersave"; EPP="power"
        notify-send -a "Power Profile" -u normal -i battery-low "Mode: ECO" "Limit: 6W/10W | Maximum Battery"
        ;;
esac

# Apply hardware power limits & governors
sudo /usr/bin/intel-undervolt apply
echo "$GOV" | sudo /usr/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
echo "$EPP" | sudo /usr/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null

# Save state
echo "$NEXT_MODE" > "$STATE_FILE"

```

Make the script executable:

```bash
chmod +x ~/toggle_power.sh

```

### 4. Configure Niri Keybindings

Add a keybinding inside your Niri configuration file (`~/.config/niri/config.kdl`) to trigger the script:

```kdl
binds {
    // Cycle power profiles using Super + P
    Mod+P { spawn "/home/rexec/toggle_power.sh"; }
}

```

---

## Verification & Stress Testing

1. **Test Sudo Rules:**
Verify that your user can apply settings without a password prompt:
```bash
sudo -k && sudo -n /usr/bin/intel-undervolt apply

```


2. **Live Monitoring & Stress Testing:**
Use `s-tui` alongside `stress-ng` to monitor real-time package power, clock frequencies, and thermal behavior while cycling through your modes:
```bash
sudo s-tui

```
