TS_FOLDER="/data/adb/tricky_store"
TS_HELPER="$TS_FOLDER/helper"

# Remove module files
rm -rf "$TS_HELPER"

# Remove legacy files
rm -rf "$TS_FOLDER/force.txt"
rm -rf "$TS_FOLDER/helper-log.txt"