homedir=$PWD
PID=$(pgrep -f rclone)
if [ -z "$var" ];
then
echo
else
    sudo kill $PID
fi
if [ -d $PWD/mountpoint ];
then 
    pwd
    sudo rm -rf $homedir/mountpoint
    sudo rm -rf $homedir/download
fi
mkdir mountpoint
mkdir download
sudo chmod 777 *
dldir=$PWD/download/
rclonedir=$PWD/mountpoint/
if [ -e $PWD/rclone.conf ];
then 
    echo "Rclone config file found !"
else
    echo "Enter rclone config link"
    read rclone_link
    wget $rclone_link
fi
echo "Enter where u want to upload: "
echo "\n===================\n"
sudo rclone --config=$PWD/rclone.conf listremotes
echo "\n===================\n"
read remote
rclone mount --daemon --config=$PWD/rclone.conf $remote $rclonedir
cd $dldir
while true
do
    echo "Enter link (Enter q to exit): "
    read linkk
    if [ $linkk == q ];
    then
        PID=$(pgrep -f rclone)
        sudo kill $PID
        cd ..
        sudo rm -rf $PWD/mountpoint
        sudo rm -rf $PWD/download
        break
    else
        aria2c --max-connection-per-server=16 '$linkk'
        sudo cp -rf $dldir/* $rclonedir
        sudo rm -rf mountpoint/*
        sudo rm -rf download/*
    fi  
done
