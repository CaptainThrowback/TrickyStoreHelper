#!/system/bin/sh
#
MODDIR=${0%/*}
#
# TrickyStore Helper Script by Captain_Throwback
#
# Add all installed packages to target.txt at boot
#
#
# NOTE: Only ONE of the below options can be set to true! 
# Leaving both options set to false will use auto mode,
# which is suitable for most devices and packages
#
# If any packages require manual leaf cert hack
# then t below flag to "true" (adds "?" to end of package name)
# If all packages should use option, then leave FORCE_LIST blank
# and make sure /data/adb/tricky_store/force.txt is not present
# (more info below)
FORCE_LEAF_HACK=true

# If any packages require manual certificate generation
# then set below flag to "true" (adds "!" to end of package name)
# If all packages should use option, then leave FORCE_LIST blank
# and make sure /data/adb/tricky_store/force.txt is not present
# (more info below)
FORCE_CERT_GEN=false

# If only specific packages require one of the above options
# (like on Pixel 9 Series devices), either add them to
# /data/adb/tricky_store/force.txt or add them to the list below
# Use the above flags to choose which manual mode should be used
# Example:
# FORCE_LIST=(
#     "icu.nullptr.nativetest"
#     "io.github.vvb2060.keyattestation"
#     "io.github.vvb2060.mahoshojo"
# )
FORCE_LIST=(
    "com.google.android.aicore"
    "com.google.android.apps.bard"
    "com.google.android.apps.pixel.agent"
    "com.google.android.apps.pixel.creativeassistant"
    "com.google.android.apps.privacy.wildlife"
    "com.google.android.apps.subscriptions.red"
    "com.google.android.apps.weather"
    "com.google.android.as"
    "com.google.android.as.oss"
    "com.google.android.gms"
    "com.google.android.gsf"
    "com.google.android.odad"
)

# The below variables shouldn't need to be changed
# unless you want to call the script something else
SCRIPTNAME="TSHelper"
LOGFILE=/data/adb/tricky_store/helper-log.txt
rm -rf "$LOGFILE"

# Set default log level
DEFAULT_LOGLEVEL=3
# 0 No logs printed
# 1 Fatal only
# 2 Fatal and Errors
# 3 Fatal, Errors, and Warnings
# 4 Fatal, Errors, Warnings, and Information
# 5 Fatal, Errors, Warnings, Information, and Debugging
# 6 All logs printed
CUSTOM_LOGLEVEL=$(getprop $SCRIPTNAME.loglevel)
if [ -n "$CUSTOM_LOGLEVEL" ]; then
	__VERBOSE="$CUSTOM_LOGLEVEL"
else
	__VERBOSE="$DEFAULT_LOGLEVEL"
fi

# Exit codes:
# 0 Success
# 1 Leaf Hack & Cert Gen both set to true

# Function for logging to logcat and log file
log_print()
{
	case $1 in
		0)
			# S: Silent (highest priority, where nothing is ever printed)
			LOG_LEVEL="S"
			;;
		1)
			# F: Fatal
			LOG_LEVEL="F"
			;;
		2)
			# E: Error
			LOG_LEVEL="E"
			;;
		3)
			# W: Warning
			LOG_LEVEL="W"
			;;
		4)
			# I: Info
			LOG_LEVEL="I"
			;; 
		5)
			# D: Debug
			LOG_LEVEL="D"
			;;
		6)
			# V: Verbose (lowest priority)
			LOG_LEVEL="V"
			;;
	esac
	if [ "$__VERBOSE" -ge "$1" ]; then
		log -p "$LOG_LEVEL" -t "$SCRIPTNAME" "$2"
	fi
	echo "$(date '+%m-%d %T.%3N') $LOG_LEVEL $SCRIPTNAME: $2" >> "$LOGFILE" 
}

log_print 4 "$SCRIPTNAME script start"
log_print 4 "Boot complete. $SCRIPTNAME processing begin"

# Location of TrickyStore files
FORCE_FILE="/data/adb/tricky_store/force.txt"
TARGET_FILE="/data/adb/tricky_store/target.txt"
TARGET_TMP="$MODDIR/target_tmp.txt"

# Add ALL the packages to target.txt
if [ ! -f "$FORCE_FILE" ] && (( ${#FORCE_LIST[@]} == 0 ))
then
    if $FORCE_LEAF_HACK && $FORCE_CERT_GEN
    then
        log_print 1 "Leaf hack and Certificate generation both set to true."
        log_print 1 "Set one or both to false for script to run properly. Script exiting."
        exit 1
    elif $FORCE_LEAF_HACK
    then
        log_print 4 "FORCE_LEAF_HACK set. Appending '?' to all package names..."
        pm list packages | cut -d ":" -f 2 | grep -Ev '^android|^com.android|com.google.android.apps.nexuslauncher|overlay|systemui|webview' | sed s/$/\?/ | sort > "$TARGET_FILE"
        log_print 4 "Script complete."
        exit 0
    elif $FORCE_CERT_GEN
    then
        log_print 4 "FORCE_CERT_GEN set. Appending '!' to all package names..." 
        pm list packages | cut -d ":" -f 2 | grep -Ev '^android|^com.android|com.google.android.apps.nexuslauncher|overlay|systemui|webview' | sed s/$/\!/ | sort > "$TARGET_FILE"
        log_print 4 "Script complete."
        exit 0
    else
        pm list packages | cut -d ":" -f 2 | grep -Ev '^android|^com.android|com.google.android.apps.nexuslauncher|overlay|systemui|webview' | sort > "$TARGET_FILE"
        log_print 4 "Packages added to target.txt. Script complete."
        exit 0
    fi
else
    pm list packages | cut -d ":" -f 2 | grep -Ev '^android|^com.android|com.google.android.apps.nexuslauncher|overlay|systemui|webview' | sort > "$TARGET_TMP"
    log_print 4 "Packages added to temp target.txt. Proceeding..."
fi

# Check for force options and set list from file or above, if enabled
if $FORCE_LEAF_HACK || $FORCE_CERT_GEN
then
    if [ -f "$FORCE_FILE" ]
    then
        FORCE_LIST=()
        while IFS='' read -r force || [ -n "$force" ]
        do
            FORCE_LIST+=("$force")
        done < "$FORCE_FILE"
    fi
else
    # We're done!
    log_print 4 "Packages added to target.txt. Script complete."
    mv -f "$TARGET_TMP" "$TARGET_FILE"
    exit 0
fi

# Update packages from Force list
rm -rf "$TARGET_FILE"
while read package
do
    for list_item in "${FORCE_LIST[@]}"
    do
        FORCE=0
        if [ "$list_item" = "$package" ]
        then
            FORCE=1
            break
        fi 
    done
    if [ "$FORCE" -eq 0 ]
    then
        echo "$package" >> "$TARGET_FILE"
    else
        if $FORCE_LEAF_HACK
        then
            echo "$package?" >> "$TARGET_FILE"
        fi
        if $FORCE_CERT_GEN
        then
            echo "$package!" >> "$TARGET_FILE"
        fi
    fi
done < "$TARGET_TMP"

rm -rf "$TARGET_TMP"

exit 0
