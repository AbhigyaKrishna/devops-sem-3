# Backup Script
This will backup your data from one directory to another directory while compressing it if specified.

### Usage
1. Clone the repository.
    ```sh
    git clone https://github.com/AbhigyaKrishna/devops-sem-3.git
    cd devops-sem-3
    ```
2. Running the script.
    ```sh
    ./backup.sh "from-dir" "to-dir"
    ```

### Options
* **r**: Specifies whether to compress it

### Dependencies
1. tar
2. date

### Notes
* It maintains a log file in the destination directory.
* It purges backups older than 7 days.