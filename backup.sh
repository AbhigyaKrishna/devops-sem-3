#!/bin/bash

while getopts 'z' OPTION
do
    case "${OPTION}" in
        z)
            zip=true
        ;;
        \?)
            echo "$0: Error: Invalid option: -${OPTARG}" >&2
            exit 1
        ;;
    esac
done

if [[ ! -d "$1" ]]; then
    echo "Specified directory '$1' doesn't exist"
    exit 1
fi

if [[ ! -d "$2" ]]; then
    echo "Specified directory '$2' doesn't exist"
    exit 1
fi

shift $((OPTIND - 1))

time=$(date +'%m-%d-%Y-%T')

if [[ $zip ]]; then
    tar -czvf "$2/backup-${time}.tar.gz" $1
    echo "Backed up at $2/backup-${time}.tar.gz"
else
    cp $1 "$2/backup-${time}"
    echo "Backed up at $2/backup-${time}"
fi

echo "[${time} UTC] Backup completed." >> "$2/backup.log"


echo "Removing older backup files..."
find "$2/*" -type f,d -mtime +6 -print | xargs rm -rf