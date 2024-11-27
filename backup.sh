#!/bin/bash

if [ "$#" -le 2 ]; then
    echo "Usage: $0 [-z] <directory> <backup_directory>"
    exit 0
fi

time=$(date +"%Y-%m-%d_%H-%M-%S")

zip=false
while getopts ":z:" OPTION
do
    case "${OPTION}" in
        z)
            zip=true
        ;;
        \?)
            echo "[${time}] $0: Error: Invalid option: -${OPTARG}"
            exit 1
        ;;
    esac
done

shift $((OPTIND - 1))

if [ ! -d "$2" ]; then
    echo "Specified directory '$2' doesn't exist. Creating directory..."
    mkdir -p "$2"
fi

if [ ! -d "$1" ]; then
    echo "[${time}] Specified directory '$1' doesn't exist" | tee -a "$2/backup.log"
    exit 1
fi

if [ $zip ]; then
    tar -czvf "$2/backup-${time}.tar.gz" "$1"
    echo "Backed up at $2/backup-${time}.tar.gz"
else
    cp "$1" "$2/backup-${time}"
    echo "Backed up at $2/backup-${time}"
fi

echo "[${time}] Backup completed." | tee -a "$2/backup.log"


echo "Removing older backup files..."
find "$2/" -type f,d -mtime +6 -print0 | xargs rm -rf