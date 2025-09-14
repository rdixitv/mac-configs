#!/bin/sh

DEFCOLOR="0xFFFFFFFF"
ALERTCOLOR="0xAAFF0000"
TOTALSWAP="$(sysctl vm.swapusage | awk '{print $4}')"

clr=""
if [ "$TOTALSWAP" != "0.00M" ]; then
    clr="$ALERTCOLOR"
else
    clr="$DEFCOLOR"
fi

sketchybar --set "$NAME" label="$TOTALSWAP" icon.color="$clr" label.color="$clr"
