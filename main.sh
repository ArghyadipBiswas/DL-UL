#!/bin/bash

custom_folder=""           # custom path of cloud
custom_filename="zipped"   # custom filename for zipped files
zip_status="0"             # set 1 for zip, 0 for not zip
unzip_status="0"           # set 1 for unzip, 0 for not unzip

function choicee() {
    while true; do
        echo -e "WELCOME" | figlet
        echo -e "Where you want to upload?\n    1. Cloud (Gdrive, OneDrive etc)\n    2. Telegram\n    3. Settings\n    4. Exit"
        read -p "Choose an option (1-4): " choice
        [[ $choice =~ ^[1-4]$ ]] && break || echo -e "\nInvalid input. Please enter a number between 1-4"
    done
}

function dl_start() {
    printf "Enter link (Enter any key to exit): "
    read linkk
    if [[ "$linkk" != "https://"* && "$linkk" != "magnet"* ]]; then
        echo -e "Not a link! Exiting! Bye"
        exit
    elif [[ "$linkk" == "https://drive.google.com/"* ]]; then 
        if grep -q "folder" <<< "$linkk"; then
            echo -e "\n\nGdrive folder detected! Downloading!"
            gdown --folder -O "$PWD/dl/" "$linkk"
        elif grep -q "file" <<< "$linkk"; then
            file_id=$(sed -n 's/.*\/d\/\([^\/]*\)\/.*/\1/p' <<< "$linkk")
            echo -e "\n\nGdrive single file detected! Downloading!"
            linkk="https://drive.google.com/uc?id=$file_id"
            gdown -O "$PWD/dl/" "$linkk"
        else
            gdown -O "$PWD/dl/" "$linkk"
        fi
    else
        TRACKERS=$(curl -Ns https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all_udp.txt | awk '$1' | tr '\n' ',')
        aria2c --allow-overwrite=true --bt-enable-lpd=true --bt-max-peers=0 --bt-tracker="[$TRACKERS]" \
            --check-certificate=false --follow-torrent=mem --max-connection-per-server=16 --max-overall-upload-limit=1K \
            --peer-agent=qBittorrent/4.3.6 --peer-id-prefix=-qB4360- --seed-time=0 --bt-tracker-connect-timeout=300 \
            --bt-stop-timeout=1200 --user-agent=qBittorrent/4.3.6 -d "$PWD/dl/" "$linkk"  
    fi
}

function initt() {
    [[ -d $PWD/dl ]] && rm -rf dl zipped unzipped
}

function rclone_setup() {
    [[ -e $PWD/rclone.conf ]] || {
        read -p "Enter rclone config link: " rclone_link
        aria2c "$rclone_link"
    }
    echo -e "Enter where you want to upload: \n==================="
    rclone --config=$PWD/rclone.conf listremotes
    echo -e "===================\n"
    read -p "Enter remote destination: " remote
}

function rclone_up() {
    rclone --config=$PWD/rclone.conf move --transfers=10 --buffer-size 256M -P "$PWD/dl/" "$1/$custom_folder"
    rm -rf "$PWD/dl/"*
    echo "Upload Done!"
}

function splitt() {
    find "$PWD/dl" -type f -print0 | while IFS= read -r -d '' filename; do
        if (( $(wc -c < "$filename") >= 2000000000 )); then
            echo "File is greater than 2GiB! Splitting"
            dir=$(dirname "$filename")
            base=$(basename "$filename")
            cd "$dir"
            split -b 2000m "$base" "$base"_part
            rm "$base"
            cd -
        fi
    done
}

function show_zip_status() {
    clear
    if ((zip_status == 1)); then
        echo -e "\n###### Change Settings ######\n###### Choose to toggle ######\n\n    1. Zipping (ON)\n    2. Unzipping (OFF)"
        if ((tg_status == 1)); then
            echo -e "    3. Telegram upload as MEDIA\n    4. Exit"
        elif ((tg_status == 0)); then
            echo -e "    3. Telegram upload as DOCUMENT\n    4. Exit"
        fi
    elif ((unzip_status == 1)); then
        echo -e "\n###### Change Settings ######\n###### Choose to toggle ######\n\n    1. Zipping (OFF)\n    2. Unzipping (ON)"
        if ((tg_status == 1)); then
            echo -e "    3. Telegram upload as MEDIA\n    4. Exit"
        elif ((tg_status == 0)); then
            echo -e "    3. Telegram upload as DOCUMENT\n    4. Exit"
        fi
    else
        echo -e "\n###### Change Settings ######\n###### Choose to toggle ######\n\n    1. Zipping (OFF)\n    2. Unzipping (OFF)"
        if ((tg_status == 1)); then
            echo -e "    3. Telegram upload as MEDIA\n    4. Exit"
        elif ((tg_status == 0)); then
            echo -e "    3. Telegram upload as DOCUMENT (Default)\n    4. Exit"
        fi
    fi
}

function tg_upload() {
    find "$PWD/dl" -type f -exec python3 up.py "{}" $tg_status \;
    rm -rf "$PWD/dl/"*
}

function zipper() {
    zip -j "$PWD/zipped/$custom_filename.zip" "$PWD/dl/"*
    rm -rf "$PWD/dl/"*
    mv "$PWD/zipped/"* "$PWD/dl/"
}

function unzipper() {
    cd "$PWD/dl/"
    for zip_file in *.zip; do
        if [[ -f "$zip_file" ]]; then
            echo "Unzipping $zip_file..."
            unzip "$zip_file" -d "${zip_file%.zip}" && rm -rf "$zip_file"
            echo "Done."
        fi
    done
    cd -
}

#====================================================================================

while true; do
    clear
    [[ -d $PWD/dl && -d zipped && -d unzipped ]] || mkdir dl zipped unzipped && chmod 777 dl zipped unzipped

    choicee
    case $choice in
        1)
            rclone_setup
            while true; do
                dl_start
                [[ $zip_status == 1 && $unzip_status != 1 ]] && zipper
                [[ $unzip_status == 1 && $zip_status != 1 ]] && unzipper
                rclone_up "$remote"
            done
            ;;
        2)
            while true; do
                dl_start
                [[ $zip_status == 1 && $unzip_status != 1 ]] && zipper
                [[ $unzip_status == 1 && $zip_status != 1 ]] && unzipper
                splitt
                echo "Starting upload!"
                sleep 1
                tg_upload
                rm -rf "$PWD/dl/"*
                echo "Done! Cleaning"
            done
            ;;
        3)
            while true; do
                show_zip_status
                read -p "Choose: " zipchoice
                case $zipchoice in
                    1)
                        ((zip_status == 1)) && zip_status=0 || zip_status=1
                        ;;
                    2)
                        ((unzip_status == 1)) && unzip_status=0 || unzip_status=1
                        ;;
                    3)
                        ((tg_status == 1)) && tg_status=0 || tg_status=1
                        ;;
                    4)
                        break
                        ;;
                esac
            done
            ;;
        4)
            initt
            exit
            ;;
        *)
            echo "Invalid choice. Exiting..."
            exit
            ;;
    esac
done
