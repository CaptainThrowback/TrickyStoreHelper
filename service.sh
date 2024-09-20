#!/system/bin/sh

MODDIR=${0%/*}

# Wait for boot_completed
resetprop -w sys.boot_completed 0 > /dev/null 2>&1

# Run helper script using system sh
/system/bin/sh "$MODDIR/helper.sh"
