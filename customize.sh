# Check for TrickyStore installation before we proceed
{ [ -d /data/adb/tricky_store ] && [ -d /data/adb/modules/tricky_store ]; } || abort "- Please install TrickyStore before installing this module."
