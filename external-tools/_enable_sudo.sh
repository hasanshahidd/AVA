#!/usr/bin/env bash
# run as root (via `wsl -u root`) — no password needed; grants hassan passwordless sudo for the setup.
echo 'hassan ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ava
chmod 440 /etc/sudoers.d/ava
visudo -cf /etc/sudoers.d/ava && echo "PASSWORDLESS-SUDO-ENABLED for hassan (revoke later: sudo rm /etc/sudoers.d/ava)"
