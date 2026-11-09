#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

# 'Global' env vars for all functions in this script
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# Release-specific variables
case $RELEASE in
	trixie)
		pipx_g=true
		;;
	bookworm)
		pipx_g=false
		;;
	resolute)
		pipx_g=true
		;;
	noble)
		pipx_g=false
		;;
	*)
		# Exit early for unsupported releases
		echo "Unsupported RELEASE: $RELEASE"
		exit 1
		;;
esac

Main() {
	case $pipx_g in
		true)
			InstallPipxPkg "rns"
			InstallPipxPkg "nomadnet"
			;;
		*)
			echo "'pipx install --global' skipped for ${RELEASE} due to old pipx version."
			echo "Target Debian 13+ or Ubuntu 26.04+ for pipx global support."
			;;
	esac
	# Always run
	ApplyFSOverlay
	BoardSpecific "$@"
	CompileDTBO
} # Main

ApplyFSOverlay() {
	# Copy overlay files to their destinations
	# replacing existing files
	cp -r /tmp/overlay/fs/* /
} # ApplyFSOverlay

InstallPipxPkg() {
	PKGSPEC="$1"
	# Install package via 'pipx install --global'
	pipx install --global "${PKGSPEC}"
	# --global flag requires pipx 1.5.0 or newer
} # InstallPipxPkg

CompileDTBO() {
	# Always compile DTBOs for each family (even if not enabled by default)
	mkdir -p /boot/overlay-user
	echo "Compiling device tree overlays for ${LINUXFAMILY}"
	echo "located in overlay/dtbo/${LINUXFAMILY}"
	shopt -s nullglob
	# If *.dts returns no results, the loop will not execute (desired behavior)
	for f in /tmp/overlay/dtbo/"${LINUXFAMILY}"/*.dts; do
		DTBO_NAME=$(basename "${f}" .dts)
		echo "Compiling ${DTBO_NAME}"
		dtc -@ -q -I dts -O dtb -o "/boot/overlay-user/${DTBO_NAME}.dtbo" "${f}"
	done
	shopt -u nullglob
} # CompileDTBO

EnableUserDTOverlay() {
	USER_OVERLAYS="$1"
	echo "Enabling user_overlays: ${USER_OVERLAYS}"
	# Enable overlays (space separated)
	# in /boot/armbianEnv.txt
	if [ -f /boot/armbianEnv.txt ]; then
		if grep -q "user_overlays=" /boot/armbianEnv.txt; then
			# Append to existing user_overlays
			sed -i "s/user_overlays=\(.*\)/user_overlays=\1 ${USER_OVERLAYS}/" /boot/armbianEnv.txt
		else
			# Add new user_overlays line
			echo "user_overlays=${USER_OVERLAYS}" >> /boot/armbianEnv.txt
		fi
	else
		echo "Warning: /boot/armbianEnv.txt not found, cannot enable device tree overlays"
	fi
} # EnableUserDTOverlay

EnableKernelDTOverlay() {
	OVERLAY_NAME="$1"
	echo "Enabling kernel (builtin) overlay: ${OVERLAY_NAME}"
	# Enable overlay in /boot/armbianEnv.txt
	if [ -f /boot/armbianEnv.txt ]; then
		if grep -q "overlays=" /boot/armbianEnv.txt; then
			# Append to existing overlays
			sed -i "s/overlays=\(.*\)/overlays=\1 ${OVERLAY_NAME}/" /boot/armbianEnv.txt
		else
			# Add new overlays line
			echo "overlays=${OVERLAY_NAME}" >> /boot/armbianEnv.txt
		fi
	else
		echo "Warning: /boot/armbianEnv.txt not found, cannot enable device tree overlays"
	fi
} # EnableKernelDTOverlay


MTSetMacSrc() {
	iface_name="$1"
	# Set the General.MACAddressSource to $iface_name
	# for meshtasticd (/etc/meshtasticd/config.yaml)
	sed -i "s/^#\?  MACAddressSource: .*/  MACAddressSource: $iface_name/" /etc/meshtasticd/config.yaml
} # MTSetMacSrc

BoardSpecific() {
	# Note: Board specific customizations may also be added via Extensions
	# See extensions/ directory

	# Unused
} # BoardSpecific

Main "$@"
