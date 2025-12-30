#!/bin/bash
# Title:                USB Safe Unmount
# Description:          Flushes writes and safely unmounts /mnt/usb. To use run the payload and ensure you confirm at prompts with all capitols "YES".
# Author:               Stuffy24
# Version:              1.0

MOUNTPOINT="/mnt/usb"

LOG "USB Safe Unmount started"

# Check if mountpoint exists
if [ ! -d "$MOUNTPOINT" ]; then
    LOG "ERROR: Mountpoint does not exist: $MOUNTPOINT"
    ERROR_DIALOG "USB mountpoint not found:\n\n$MOUNTPOINT\n\nNothing to unmount."
    exit 1
fi

# Check if mounted
if ! grep -qsE "[[:space:]]$MOUNTPOINT[[:space:]]" /proc/mounts; then
    LOG "USB is not mounted at $MOUNTPOINT"
    ERROR_DIALOG "USB is not currently mounted.\n\nIt is safe to remove if already unplugged."
    exit 0
fi

LOG "USB is mounted — preparing to unmount"

# First confirmation (safety)
confirm=$(TEXT_PICKER "Safely unmount USB now? Type YES to proceed" "NO")
case $? in
    $DUCKYSCRIPT_CANCELLED|$DUCKYSCRIPT_REJECTED|$DUCKYSCRIPT_ERROR)
        LOG "User cancelled unmount"
        exit 0
        ;;
esac

confirm_upper="$(echo "$confirm" | tr '[:lower:]' '[:upper:]')"
if [ "$confirm_upper" != "YES" ]; then
    LOG "Unmount aborted — confirmation not YES"
    exit 0
fi

# Flush all pending writes
LOG "Flushing write buffers (sync)"
sync

# Attempt unmount
if umount "$MOUNTPOINT" 2>/dev/null; then
    LOG "USB unmounted successfully from $MOUNTPOINT"
    LOG "It is now safe to remove the USB device"
else
    LOG "ERROR: Failed to unmount $MOUNTPOINT"
    ERROR_DIALOG "Failed to unmount USB.\n\nCommon causes:\n- A payload is still writing to USB\n- A shell is using /mnt/usb\n\nStop active payloads, wait a few seconds, and try again."
    exit 1
fi

LOG "USB Safe Unmount complete"
