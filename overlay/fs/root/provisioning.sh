passwd -dl reticulum # Disable login
cp -r ret /home/reticulum/.reticulum
chown -R reticulum:reticulum ret /home/reticulum/.reticulum

su - reticulum -c "python3 -m venv r_venv; ~/r_venv/bin/pip install rns nomadnet"
