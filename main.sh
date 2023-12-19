#!/bin/bash

function initt(){
    if [[ $(mount | grep -q "$PWD/ul") ]]; then
        echo -e "Rclone is mounted! Unmounting!"
        kill $(pgrep -f rclone)
        fusermount -u "$PWD/ul/"
    fi
    if [[ -d $PWD/dl && -d $PWD/ul ]]; then
        rm -rf dl ul
    fi
}

function choicee(){
    while true; do
        echo -e "Where you want to upload ?\n    1.Cloud (Gdrive, OneDrive etc)\n    2.Telegram (Beta)\n    3.Exit"
        read choice
        if [[ $choice == 1 || $choice == 2 || $choice == 3 ]]; then
            break
        else
            echo -e "\nInvalid input. Please enter a number between 1 and 2."
        fi
    done
}

function rclone_mount(){
    if [ -e $PWD/rclone.conf ]; then 
        echo -e "Rclone config file found !\n"
    else
        echo "Enter rclone config link : "
        read rclone_link
        wget $rclone_link
    fi
    echo -e "Enter where you want to upload: \n==================="
    rclone --config=$PWD/rclone.conf listremotes
    echo -e "===================\n"
    read remote
    rclone mount --daemon --config=$PWD/rclone.conf $remote "$PWD/ul"
}

function dl_start(){
    echo -e "Enter link (Enter q to exit) : "
    read linkk
    echo $linkk
    if [[ "$linkk" == "q" ]]; then
        initt
        clear
        echo "Thanks for using my! Bye buddy!"
        exit
    elif [[ "$linkk" != "https://"* ]]; then
        clear
        echo -e "Not a link! Exiting! Bye"
        exit
    elif [[ "$linkk" == "https://drive.google.com/"* ]]; then 
        echo -e "\nGdrive link detected! Downloading..."
        gdown -O "$PWD/dl/" "$linkk"
    else
        TRACKERS=$(curl -Ns https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_udp.txt | awk '$1' | tr '\n' ',')
        aria2c --allow-overwrite=true --bt-enable-lpd=true --bt-max-peers=0 --bt-tracker="[$TRACKERS]" --check-certificate=false --follow-torrent=mem --max-connection-per-server=16 --max-overall-upload-limit=1K --peer-agent=qBittorrent/4.3.6 --peer-id-prefix=-qB4360- --seed-time=0 --bt-tracker-connect-timeout=300 --bt-stop-timeout=1200 --user-agent=qBittorrent/4.3.6 -d "$PWD/dl/" "$linkk"  
    fi
}

function rclone_up(){
    cp "$PWD/dl/"* "$PWD/ul/$custom_folder"
    rm -rf $PWD/dl/*
    echo "Upload Done!"
}

# function splitt(){
#     mkdir ${1}tmp
#     cp 
# }

function splitt(){
    for filename in "$(find $PWD -type f)"; do
        if [ $(wc -c < "$filename") -ge 2000000000 ]; then
            echo "File is greater than 2GiB! Splitting"
            find $PWD/dl -type f -size +2G -exec split -b 2000m {} {}_part \; -exec rm {} \;
        elif [ $(wc -c < "$filename") -lt 2000000000 ]; then
            find $PWD/dl -type f -exec python3 up.py {} \;
        fi
    done
}

#################### End of Functions #############

clear
custom_folder="" # custom path of cloud
if [[ -d $PWD/ul && -d $PWD/dl ]]; then
    echo "No need to create directory again!"
else
    mkdir dl ul
    chmod 777 dl ul
fi
choicee
if [[ $choice == 1 ]]; then
    if [[ $(mount | grep -q "$PWD/ul") ]]; then
        echo -e "Rclone is already mounted!"
    else
        rclone_mount
    fi
    while true; do
        dl_start
        rclone_up
    done
elif [[ $choice == 2 ]]; then
    echo "Work in progress! Currently in beta state!"
    dl_start
    splitt
    echo "Done! Cleaning"
elif [[ $choice == 3 ]]; then
    initt
    exit
else
    echo "Bruh"
fi
