#!/system/bin/sh
#
MODDIR=${0%/*}
#
# TrickyStore Helper Script by Captain_Throwback
#
# Add all installed packages to target.txt at boot
#
#
# The below variable shouldn't need to be changed
# unless you want to call the log/tag something else
SCRIPTNAME="TSHelper"

# Module files
TS_FOLDER="/data/adb/tricky_store"
TS_HELPER="$TS_FOLDER/helper"
CONFIG_FILE="$TS_HELPER/config.txt"
EXCLUDE_FILE="$TS_HELPER/exclude.txt"
FORCE_FILE="$TS_HELPER/force.txt"
LOG_FILE="$TS_HELPER/$SCRIPTNAME.log"

# Prepare the folders
if [ -d "$TS_FOLDER" ]
then
    mkdir -p "$TS_HELPER"
else
    FATAL_ERROR="TrickyStore folder not found. Please install TrickyStore to use this module."
    log -p "F" -t "$SCRIPTNAME" "$FATAL_ERROR"
    echo "$FATAL_ERROR"
    exit 1
fi

# Set default log level
DEFAULT_LOGLEVEL=3
# 0 No logs printed
# 1 Fatal only
# 2 Fatal and Errors
# 3 Fatal, Errors, and Warnings
# 4 Fatal, Errors, Warnings, and Information
# 5 Fatal, Errors, Warnings, Information, and Debugging
# 6 All logs printed
if [ -f "$CONFIG_FILE" ]
then
    CUSTOM_LOGLEVEL=$(grep '^CUSTOM_LOGLEVEL=' $CONFIG_FILE | cut -d '=' -f 2)
fi
if [ -n "$CUSTOM_LOGLEVEL" ]
then
	__VERBOSE="$CUSTOM_LOGLEVEL"
else
	__VERBOSE="$DEFAULT_LOGLEVEL"
fi

# Exit codes:
# 0 Success
# 1 TrickyStore folder missing
# 2 Leaf Hack & Cert Gen both set to true

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
	if [ "$__VERBOSE" -ge "$1" ]
    then
		log -p "$LOG_LEVEL" -t "$SCRIPTNAME" "$2"
	fi
	echo "$(date '+%m-%d %T.%3N') $LOG_LEVEL $SCRIPTNAME: $2" >> "$LOG_FILE" 
}

# Clear old files
rm -rf "$LOG_FILE"
rm -rf "$TARGET_TMP"
rm -rf "$TARGET_FILE"

# DEBUG: Base Logging
log_print 5 "LOGLEVEL=$__VERBOSE"

# NOTE: Only ONE of the below options can be set to true! 
# Leaving both options set to false will use auto mode,
# which is suitable for most devices and packages
#
# If any packages require manual leaf cert hack
# then set below flag to "true" (adds "?" to end of package name)
# If all packages should use option, then leave FORCE_LIST blank
# and make sure /data/adb/tricky_store/helper/force.txt is not present
# (more info below)
if [ -f "$CONFIG_FILE" ]
then
    FORCE_LEAF_HACK=$(grep '^FORCE_LEAF_HACK=' "$CONFIG_FILE" | cut -d '=' -f 2)
fi
if [ -z "$FORCE_LEAF_HACK" ]
then
    FORCE_LEAF_HACK=false
fi
# DEBUG: Base Logging
log_print 5 "FORCE_LEAF_HACK=$FORCE_LEAF_HACK"

# If any packages require manual certificate generation
# then set below flag to "true" (adds "!" to end of package name)
# If all packages should use option, then leave FORCE_LIST blank
# and make sure /data/adb/tricky_store/helper/force.txt is not present
# (more info below)
if [ -f "$CONFIG_FILE" ]
then
    FORCE_CERT_GEN=$(grep '^FORCE_CERT_GEN=' "$CONFIG_FILE" | cut -d '=' -f 2)
fi
if [ -z "$FORCE_CERT_GEN" ]
then
    FORCE_CERT_GEN=false
fi
# DEBUG: Base Logging
log_print 5 "FORCE_CERT_GEN=$FORCE_CERT_GEN"

if $FORCE_LEAF_HACK && $FORCE_CERT_GEN
    then
        log_print 1 "Leaf hack and Certificate generation both set to true."
        log_print 1 "Set one or both to false to run properly. Script exiting."
        exit 2
fi

add_to_list() {
    if [ -f "$1" ]
    then
        PACKAGE_LIST=()
        while IFS='' read -r package || [ -n "$package" ]
        do
            PACKAGE_LIST+=("$package")
        done < "$1"
        case "$2" in
            "EXCLUDE_LIST")
                EXCLUDE_LIST=("${PACKAGE_LIST[@]}")
                ;;
            "FORCE_LIST")
                FORCE_LIST=("${PACKAGE_LIST[@]}")
                ;;
        esac
    fi
}

process_package_list() {
    while read package
    do
        case "$1" in
            "EXCLUDE_LIST")
                PACKAGE_LIST=("${EXCLUDE_LIST[@]}")
                ;;
            "FORCE_LIST")
                PACKAGE_LIST=("${FORCE_LIST[@]}")
                ;;
        esac
        for list_item in "${PACKAGE_LIST[@]}"
        do
            EXISTS=0
            if [ "$list_item" = "$package" ]
            then
                EXISTS=1
                break
            fi 
        done
        case "$1" in
            "EXCLUDE_LIST")
                if [ "$EXISTS" -eq 1 ]
                then
                    sed -i "/^$package$/d" "$TARGET_FILE"
                fi
                ;;
            "FORCE_LIST")
                if [ "$EXISTS" -eq 1 ]
                then
                    if $FORCE_LEAF_HACK && (( ${#FORCE_LIST[@]} != 0 ))
                    then
                        sed -i s/"$package"$/"$package"\?/ "$TARGET_FILE"
                    fi
                    if $FORCE_CERT_GEN && (( ${#FORCE_LIST[@]} != 0 ))
                    then
                        sed -i s/"$package"$/"$package"\!/ "$TARGET_FILE"
                    fi
                fi
                ;;
        esac
    done < "$TARGET_FILE"
}

finish_success() {
    log_print 4 "Script complete."
    exit 0
}

# If specific packages need to be excluded from the target list,
# add them to /data/adb/tricky_store/helper/exclude.txt
# Use the above flags to choose which manual mode should be used
add_to_list "$EXCLUDE_FILE" "EXCLUDE_LIST"

# Default exclusions
DEFAULT_EXCLUSIONS=(
    "^android"
    "^com.android"
    "com.google.android.apps.nexuslauncher"
    "overlay"
    "systemui"
    "webview"
)
if [ -f "$CONFIG_FILE" ]
then
    USE_DEFAULT_EXCLUSIONS=$(grep '^USE_DEFAULT_EXCLUSIONS=' "$CONFIG_FILE" | cut -d '=' -f 2)
fi
if [ -z "$USE_DEFAULT_EXCLUSIONS" ]
then
    USE_DEFAULT_EXCLUSIONS=true
fi
if [ "$USE_DEFAULT_EXCLUSIONS" = "true" ]
then
    DEFAULT_EXCLUSIONS_LIST=$(printf '%s|' "${DEFAULT_EXCLUSIONS[@]}")
fi

# DEBUG: Base Logging
log_print 5 "USE_DEFAULT_EXCLUSIONS=$USE_DEFAULT_EXCLUSIONS"

# If only specific packages require one of the above options,
# add them to /data/adb/tricky_store/helper/force.txt
# Use the above flags to choose which manual mode should be used
add_to_list "$FORCE_FILE" "FORCE_LIST"

# Script processing start
log_print 4 "$SCRIPTNAME script start"
log_print 4 "Boot complete. $SCRIPTNAME processing "

# Location of TrickyStore files
TARGET_FILE="$TS_FOLDER/target.txt"

# Add ALL the packages to target.txt
if [ -n "$DEFAULT_EXCLUSIONS_LIST" ]
then
    pm list packages | cut -d ":" -f 2 | grep -Ev "${DEFAULT_EXCLUSIONS_LIST%?}" | sort > "$TARGET_FILE"
else
    pm list packages | cut -d ":" -f 2 | sort > "$TARGET_FILE"
fi

# Remove excluded packages
if (( ${#EXCLUDE_LIST[@]} != 0 ))
then
    process_package_list "EXCLUDE_LIST"
fi

# Tag force packages
if (( ${#FORCE_LIST[@]} == 0 ))
then
    if $FORCE_LEAF_HACK
    then
        log_print 4 "FORCE_LEAF_HACK set. Appending '?' to all package names..."
        sed -i s/$/\?/ "$TARGET_FILE"
        finish_success
    elif $FORCE_CERT_GEN
    then
        log_print 4 "FORCE_CERT_GEN set. Appending '!' to all package names..." 
        sed -i s/$/\!/ "$TARGET_FILE"
        finish_success
    else
        finish_success
    fi
else
    if $FORCE_LEAF_HACK || $FORCE_CERT_GEN
    then
        process_package_list "FORCE_LIST"
    fi
fi

finish_success
