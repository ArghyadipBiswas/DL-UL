#!/bin/bash

function choicee(){
    while true; do
        echo -e "Where you want to upload ?\n    1.Cloud (Gdrive, OneDrive etc)\n    2.Telegram\n    3.Exit"
        read choice
        if [[ $choice == 1 || $choice == 2 || $choice == 3 ]]; then
            break
        else
            echo -e "\nInvalid input. Please enter a number between 1-3"
        fi
    done
}

function dl_start(){
    clear
    echo -e "Enter link (Enter any key to exit): "
    read linkk
    if [[ "$linkk" != "https://"* ]]; then
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

function initt(){
    if [[ -d $PWD/dl ]]; then
        rm -rf dl ul
    fi
}

function rclone_setup(){
    if [ -e $PWD/rclone.conf ]; then 
        echo -e "Rclone config file found !\n"
    else
        echo "Enter rclone config link : "
        read rclone_link
        aria2c $rclone_link
    fi
    echo -e "Enter where you want to upload: \n==================="
    rclone --config=$PWD/rclone.conf listremotes
    echo -e "===================\n"
    read remote
}

function rclone_up(){
    # clear
    rclone --config=$PWD/rclone.conf move --transfers=10 --buffer-size 256M -P $PWD/dl/ $1\/$custom_folder
    rm -rf $PWD/dl/*
    echo "Upload Done!"
}

function splitt(){
    for filename in "$(find $PWD/dl -type f)"; do
        if [[ $(wc -c < "$filename") -ge 2000000000 ]]; then
            echo "File is greater than 2GiB! Splitting"
            find $PWD/dl -type f -size +2G -exec split -b 2000m {} {}_part \; -exec rm {} \;
        fi
    done
}

function tg_upload(){
    find $PWD/dl -type f -exec python3 up.py {} \;
}

#====================================================================================

clear
custom_folder="" # custom path of cloud

if [[ -d $PWD/dl ]]; then
    echo "No need to create directory again!"
else
    mkdir dl
    chmod 777 dl
fi
choicee
if [[ $choice == 1 ]]; then
    rclone_setup
    while true; do
        dl_start
        rclone_up $remote
    done
elif [[ $choice == 2 ]]; then
    while true; do
        dl_start
        splitt
        echo "Starting upload!"
        sleep 1
        tg_upload
        rm -rf $PWD/dl/*
        echo "Done! Cleaning"
    done
elif [[ $choice == 3 ]]; then
    initt
    exit
else
    echo "Bruh"
fi
