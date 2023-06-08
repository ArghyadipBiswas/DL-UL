pwd
mkdir tempfiles
chmod +x tempfiles
rclonedir=$PWD/tempfiles
echo "Enter rclone config link"
read rclone_link
wget $rclone_link
echo "Enter where u want to upload: "
echo "\n===================\n"
rclone --config=$PWD/rclone.conf listremotes
echo "\n===================\n"
read remote
rclone mount --daemon --config=$PWD/rclone.conf $remote $PWD/tempfiles/
mkdir dl
chmod +x dl
dldir=$PWD/dl/
cd $dldir
echo "Enter link : "
read linkk
aria2c --max-connection-per-server=16 $linkk
cp $dldir/* $rclonedir
rm $dldir/*
