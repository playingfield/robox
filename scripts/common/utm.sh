#!/bin/bash

retry() {
  local COUNT=1
  local DELAY=0
  local RESULT=0
  while [[ "${COUNT}" -le 10 ]]; do
    [[ "${RESULT}" -ne 0 ]] && {
      [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput setaf 1
      echo -e "\n${*} failed... retrying ${COUNT} of 10.\n" >&2
      [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput sgr0
    }
    "${@}" && { RESULT=0 && break; } || RESULT="${?}"
    COUNT="$((COUNT + 1))"
    DELAY="$((DELAY + 10))"
    sleep $DELAY
  done
  [[ "${COUNT}" -gt 10 ]] && {
    [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput setaf 1
    echo -e "\nThe command failed 10 times.\n" >&2
    [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput sgr0
  }
  return "${RESULT}"
}

printf "Installing UTM guest support tools.\n"

# spice-vdagent: clipboard sharing and dynamic display resolution
# qemu-guest-agent: time syncing and guest scripting
# spice-webdavd: directory sharing (SPICE WebDAV)

if [ -f "/bin/dnf" ] || [ -f "/usr/bin/dnf" ]; then
    retry dnf --assumeyes install spice-vdagent qemu-guest-agent spice-webdavd
    systemctl enable spice-vdagentd qemu-guest-agent 2>/dev/null || true
elif [ -f "/bin/yum" ] || [ -f "/usr/bin/yum" ]; then
    retry yum --assumeyes install spice-vdagent qemu-guest-agent spice-webdavd
    systemctl enable spice-vdagentd qemu-guest-agent 2>/dev/null || true
elif [ -f "/usr/bin/apt-get" ]; then
    export DEBIAN_FRONTEND=noninteractive
    export DEBCONF_NONINTERACTIVE_SEEN=true
    retry apt-get --assume-yes install spice-vdagent qemu-guest-agent spice-webdavd
    systemctl enable spice-vdagentd qemu-guest-agent 2>/dev/null || true
elif [ -f "/usr/bin/zypper" ]; then
    retry zypper --non-interactive install spice-vdagent qemu-guest-agent spice-webdavd
    systemctl enable spice-vdagentd qemu-guest-agent 2>/dev/null || true
elif [ -f "/usr/bin/pacman" ]; then
    retry pacman --sync --noconfirm --noprogressbar spice-vdagent qemu-guest-agent phodav
    systemctl enable spice-vdagentd qemu-guest-agent 2>/dev/null || true
elif [ -f "/sbin/apk" ]; then
    retry apk add --no-cache qemu-guest-agent
    rc-update add qemu-guest-agent default
fi
