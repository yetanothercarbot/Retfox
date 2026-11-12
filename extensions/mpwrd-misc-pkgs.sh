# Install misc packages
# Not necessary for mPWRD-OS core functionality, but nice to have around.

function extension_prepare_config__add_mpwrd_misc() {
    # Python
    add_packages_to_image python3 python3-pip python3-cffi python3-venv python3-cryptography
	# Misc
	add_packages_to_image vim git net-tools fonts-noto-color-emoji i2c-tools
}
