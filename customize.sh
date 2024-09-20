TS_FOLDER="/data/adb/tricky_store"
TS_MODULE_FOLDER="/data/adb/modules/tricky_store"

# Check for TrickyStore installation before we proceed
{ [ -d "$TS_FOLDER" ] && [ -d "$TS_MODULE_FOLDER" ]; } || abort "- Please install TrickyStore before installing this module."

TS_HELPER="$TS_FOLDER/helper"

# Prepare the helper folder
mkdir "$TS_HELPER"
echo "FORCE_LEAF_HACK=false">"$TS_HELPER/config.txt"
echo "FORCE_CERT_GEN=false">>"$TS_HELPER/config.txt"
touch "$TS_HELPER/exclude.txt"
touch "$TS_HELPER/force.txt"
