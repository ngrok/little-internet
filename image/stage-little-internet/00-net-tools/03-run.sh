#!/bin/bash -e

# Let the default user capture packets without sudo, and give them a place to
# put the captures.
#
# 00-debconf preseeds wireshark-common/install-setuid=true, so installing
# tshark/wireshark-common created the 'wireshark' group and gave dumpcap the
# capture capabilities (mode 0750, root:wireshark). tshark captures through
# dumpcap, so adding the user to that group is all it takes to run `tshark`
# unprivileged. Use an *unquoted* heredoc so ${FIRST_USER_NAME} expands on the
# host before running inside the chroot.
on_chroot << EOF
adduser ${FIRST_USER_NAME} wireshark

# Pre-create ~/cap so the lessons can write capture files there without anyone
# having to mkdir it first. Created inside the chroot so ownership resolves to
# the first user's uid/gid.
install -d -o ${FIRST_USER_NAME} -g ${FIRST_USER_NAME} -m 755 \
	/home/${FIRST_USER_NAME}/cap
EOF
