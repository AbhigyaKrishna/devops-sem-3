# Jenkins Installation Script
This script is used to install jenkins (any version) on any unix based (linux or mac) operating systems. It handles installing jenkins with systemd service.

**Note:** Windows is currently not supported.

### Installation
1. Clone the repository.
    ```sh
    git clone https://github.com/AbhigyaKrishna/devops-sem-3.git
    cd devops-sem-3
    ```
2. Running the script.
    ```sh
    ./install-jenkins.sh
    ```

### Supported System and Versions
| Operating System | LTS/Unstable | All Version |
| :----------- | :----------: | :----------: |
| Ubuntu | ✅ | ✅ |
| Fedora | ✅ | ✅ |
| Red Hat | ✅ | ✅ |
| Arch | ✅ | ❌ |
| Opensuse | ✅ | ✅ |
| Mac | ✅ | ❌ |
| Windows | ❌ | ❌ |

### Dependencies
1. wget
2. curl
3. update-alternatives (debian, opensuse)
4. alternatives (fedora, red-hat)
5. archlinux-java (arch)
6. homebrew (macos)

### Usage
You can access jenkins on the endpoint `http://localhost:8080` ot `http://localhost:8090` on arch linux.

Initial password can be found in:
* Linux: `/var/lib/jenkins/secrets/initialAdminPassword`
* MacOs: `/Users/<your-user>/.jenkins/secrets/initialAdminPassword`

### Notes
* **Linux:** This script will try to install jenkins through your package manager (apt, dnf or yum) and will change the default java version.
* **Arch Linux:** It will install [yay](https://github.com/Jguer/yay) (an aur package manager) and install jenkins through it.
* **Mac:** It will install [homebrew](https://brew.sh/) if not found and will try to install jenkins through [homebrew](https://brew.sh/).