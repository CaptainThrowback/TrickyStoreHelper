TS_FOLDER="/data/adb/tricky_store"
TS_MODULE_FOLDER="/data/adb/modules/tricky_store"

# Check for TrickyStore installation before we proceed
{ [ -d "$TS_FOLDER" ] && [ -d "$TS_MODULE_FOLDER" ]; } || abort "- Please install TrickyStore before installing this module."

TS_HELPER="$TS_FOLDER/helper"
CONFIG_FILE="$TS_HELPER/config.txt"
EXCLUDE_FILE="$TS_HELPER/exclude.txt"
FORCE_FILE="$TS_HELPER/force.txt"

# Clean up old module remnant
rm -rf "$TS_FOLDER/helper-log.txt"

# Prepare the helper folder
if [ ! -d "$TS_HELPER" ]
then
    mkdir "$TS_HELPER"
fi
if [ ! -f "$CONFIG_FILE" ]
then
    echo "FORCE_LEAF_HACK=false">"$TS_HELPER/config.txt"
    echo "FORCE_CERT_GEN=false">>"$TS_HELPER/config.txt"
    echo "USE_DEFAULT_EXCLUSIONS=true">>"$TS_HELPER/config.txt"
fi
if [ ! -f "$EXCLUDE_FILE" ]
then
    touch "$TS_HELPER/exclude.txt"
fi
if [ -f "$TS_FOLDER/force.txt" ]
then
    mv "$TS_FOLDER/force.txt" "$TS_HELPER/force.txt"
fi
if [ ! -f "$FORCE_FILE" ]
then
    touch "$TS_HELPER/force.txt"
fi
