#for ARCH users (pacman)
sudo pacman -Syu python3 python3-pip
pip install rclone aria2 fuse python python-pip --break-system-packages
pip install -r requirements.txt --break-system-packages
