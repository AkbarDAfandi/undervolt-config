#!/bin/bash

STATE_FILE="/tmp/power_mode"
MONITOR="eDP-1"
RES="1920x1080"

# Read current state (default to 0 if state file missing)
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
