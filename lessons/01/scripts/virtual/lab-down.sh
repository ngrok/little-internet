#!/usr/bin/env bash
# Tear down the namespace lab. Deleting the namespaces removes the veth pair
# with them.
set -uo pipefail
A="${A:-pi-a}"
B="${B:-pi-b}"

ip netns del "$A" 2>/dev/null && echo "removed $A" || echo "($A not present)"
ip netns del "$B" 2>/dev/null && echo "removed $B" || echo "($B not present)"
echo "Lab down."
