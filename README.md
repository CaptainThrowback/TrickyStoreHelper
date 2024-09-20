TrickyStore Helper

For adding more files to target.txt automatically on device boot.

All files are stored in /data/adb/tricky_store/helper folder.

Inside that folder, there are 4 files:

config.txt
This is where you can modify the default configuration options for the module. By default, the available options are:

FORCE_LEAF_HACK (default value "false")
- This adds "?" to either all package names, or ones defined in "force.txt"

FORCE_CERT_GEN (default value "false")
- This adds "!" to either all package names, or ones defined in "force.txt"

USE_DEFAULT_EXCLUSIONS (default value "true")
- This excludes a predefined default list of packages for target.txt, which should be irrelevant for spoofing a locked bootloader

CUSTOM_LOGLEVEL (not included by default)
- This allows adding debug logging to be logged to logcat, with the tag "TSHelper". This may be helpful if there is an issue booting the device.

exclude.txt
This file contains a list of packages that you want excluded from target.txt. This may be useful if some app is having issues because of spoofing. If no packages need to be excluded, then this file should remain empty.

force.txt
This file contains a list of specific packages that you want either the leaf hack or certificate generation applied to. For this list to be applied, either of those force options will need to be set to true (but not both). If you want to globally apply either, then this list should remain empty.

TSHelper.log
Log file for the module. ALL logging will appear in this file, regardless of the log level that is set.