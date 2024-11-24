#!/bin/bash

download() {
  if [ "$2" ]; then
    wget -O "$2" "$1" -q --show-progress
  else
    wget "$1" -q --show-progress
  fi
}

detect_os() {
  case $OSTYPE in
  linux-gnu*) echo "linux";;
  darwin*) echo "mac";;
  win32* | cygwin*) echo "win";;
  esac
}

detect_supported_java() {
  local minor
  minor=$(echo "$1" | awk -F '.' '{print $2}')

  if [ "$minor" -ge "463" ]; then
    return "$($2 -ge '17' && $2 -le '21')"
  elif [ "$minor" -ge "419" ]; then
    return "$($2 -ge '11' && $2 -le '21')"
  elif [ "$minor" -ge "357" ]; then
    return "$($2 -ge '11' && $2 -le '17')"
  elif [ "$minor" -ge "340" ]; then
    return "$($2 -ge '8' && $2 -le '17')"
  else
    return "$($2 -ge '8' && $2 -le '11')"
  fi
}

required_java_version() {
  local minor
  minor=$(echo "$1" | awk -F '.' '{print $2}')

  if [ "$minor" -ge "340" ]; then
    echo "17"
  else
    echo "8"
  fi
}

download_jenkins_generic_linux() {
  if [ "$download_java" ]; then
    echo "Downloading java..."
    download https://builds.openlogic.com/downloadJDK/openlogic-openjdk/17.0.13+11/openlogic-openjdk-17.0.13+11-linux-x64.tar.gz java.tar.gz
    tar -xvzf java.tar.gz
    mv openlogic-openjdk-17.0.13+11-linux-x64 java
  fi

  local jenkins_path
  jenkins_path="/usr/share/jenkins"
  sudo mkdir -p "${jenkins_path}"
  sudo mv java "${jenkins_path}"
  sudo mv jenkins.war "${jenkins_path}/jenkins.war"
  sudo mkdir -p /var/cache/jenkins
  sudo mkdir -p /var/lib/jenkins

  local jenkins_config
  jenkins_config="/etc/conf.d/jenkins"
  exec 5>&1 > jenkins.conf
  echo "JAVA=${jenkins_path}/java/bin/java"
  echo "JAVA_ARGS=-Xmx512m"
  echo "JAVA_OPTS="
  echo "JENKINS_USER=jenkins"
  echo "JENKINS_HOME=/var/lib/jenkins"
  echo "JENKINS_WAR=${jenkins_path}/jenkins.war"
  echo "JENKINS_WEBROOT=--webroot=/var/cache/jenkins"
  echo "JENKINS_PORT=--httpPort=8080"
  echo "JENKINS_OPTS="
  echo "JENKINS_COMMAND_LINE=\"\$JAVA \$JAVA_ARGS \$JAVA_OPTS -jar \$JENKINS_WAR \$JENKINS_WEBROOT \$JENKINS_PORT \$JENKINS_OPTS\""
  exec 1>&5 5>&-
  sudo mkdir -p /etc/conf.d
  sudo mv jenkins.conf "${jenkins_config}"

  curl -sSL https://aur.archlinux.org/cgit/aur.git/plain/jenkins.service?h=jenkins-lts > jenkins.service
  sudo mv jenkins.service /usr/lib/systemd/system/jenkins.service

  echo "d /var/cache/jenkins 0755 jenkins jenkins -" > jenkins.temp
  sudo mv jenkins.temp /usr/lib/tmpfiles.d/jenkins.conf

  printf "u jenkins - \"Jenkins CI\" /var/lib/jenkins\ng jenkins -" > jenkins.sysuser
  sudo mv jenkins.sysuser /usr/lib/sysusers.d/jenkins.conf

  sudo systemctl daemon-reload
  sudo systemctl enable jenkins
  sudo systemctl start jenkins
}

os=$(detect_os)
echo "Detected operating system: $os"

echo "Fetching version..."
stable_version=$(curl -sSL --max-redirs 2 https://updates.jenkins.io/stable/latestCore.txt)
unstable_version=$(curl -sSL --max-redirs 2 https://updates.jenkins.io/current/latestCore.txt)
echo "Stable/Lts version: $stable_version"
echo "Unstable/Weekly version: $unstable_version"

if [ -x "$(command -v java)"  ]; then
  java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
  echo "Detected java version: $java_version"
  java_version=$(echo "$java_version" | awk -F '.' '{print $1}')
else
  java_version="0"
  echo "Java not installed"
fi

echo "Enter jenkins version to install."
echo "[l]ts  [u]nstable  or write version number"
read -rp "Default: l >> " version
if [ ! "$version" ] || [ "$version" == "l" ]; then
  version="lts"
elif [ "$version" == "u" ]; then
  version="unstable"
fi

download_java=$(detect_supported_java "$version" "$java_version")
if [ "$download_java" ]; then
  download_java=$(required_java_version "$version")
  echo "Required java version: $download_java"
fi

#echo "Downloading jenkins version: ${version}"
# download jenkins.war "https://github.com/jenkinsci/jenkins/releases/download/jenkins-${version}/jenkins.war"

if [ "$os" == "linux" ]; then
  if [ "$version" == "lts" ] || [ "$version" == "unstable" ]; then
    if [ -x "$(command -v apt-get)" ]; then
      # debian
      if [ "$download_java" ]; then
        sudo apt-get install "openjdk-$download_java-jre" -y
        sudo update-alternatives --set java "$(sudo update-alternatives --list java | grep "java-$download_java-openjdk")"
      fi

      if [ "$version" == "lts" ]; then
        sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
        echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
      else
        sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
        echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
      fi

      sudo apt-get update
      sudo apt-get install fontconfig jenkins -y
    elif [ -x "$(command -v rpm)" ]; then
      if [ "$version" == "lts" ]; then
        sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
        sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
      else
        sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
        sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io-2023.key
      fi

      if [ -x "$(command -v dnf)" ]; then
        # fedora
        if [ "$download_java" ]; then
          sudo dnf install --assumeyes "java-$download_java-openjdk"-y
          sudo alternatives --set java "$(sudo update-alternatives --list java | grep "java-$download_java-openjdk")"
        fi

        sudo dnf upgrade
        sudo dnf install --assumeyes fontconfig jenkins
      elif [ -x "$(command -v yum)" ]; then
        # red hat
        if [ "$download_java" ]; then
          sudo yum -y install "java-$download_java-openjdk" -y
          sudo alternatives --set java "$(sudo alternatives --list java | grep "java-$download_java-openjdk")"
        fi

        sudo yum upgrade
        sudo -y yum install fontconfig jenkins
      fi
    elif [ -x "$(command -v pacman)" ]; then
      # arch
      if [ "$version" == "lts" ]; then
        if [ -x "$(command -v yay)" ]; then
          yay -S --save --nocleanmenu --nodiffmenu jenkins-lts
        else
          git clone https://aur.archlinux.org/jenkins-lts.git
          cd jenkins-lts || exit
          makepkg -si
          cd ..
          rm -rf jenkins-lts
        fi
      else
        if [ "$download_java" ]; then
          sudo pacman -S --noconfirm "java-$download_java-openjdk"
          sudo archlinux-java set "java-$download_java-openjdk"
        fi

        sudo pacman -S --noconfirm fontconfig jenkins
      fi

      sudo usermod -s /bin/bash jenkins
    elif [ -x "$(command -v zypper)" ]; then
      # opensuse
      if [ "$version" == "lts" ]; then
        zypper addrepo -f https://pkg.jenkins.io/opensuse-stable/ jenkins
      else
        sudo zypper addrepo -f https://pkg.jenkins.io/opensuse/ jenkins
      fi

      if [ "$download_java" ]; then
        sudo zypper install -y "java-$download_java-openjdk"
        sudo update-alternatives --set java "$(sudo alternatives --list java | grep "java-$download_java-openjdk")"
      fi

      sudo zypper install -y dejavu-fonts fontconfig jenkins
      sudo mkdir -p /var/cache/jenkins/tmp
      sudo chown -R jenkins:jenkins /var/cache/jenkins/tmp

    else
      download_jenkins_generic_linux
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
  else
    if [ -x "$(command -v apt-get)" ]; then
      if [ "$download_java" ]; then
        sudo apt-get install "openjdk-$download_java-jre" -y
        sudo update-alternatives --set java "$(sudo update-alternatives --list java | grep "java-$download_java-openjdk")"
      fi

      sudo apt-get install fontconfig -y
      download "https://github.com/jenkinsci/jenkins/releases/download/jenkins-$version/jenkins_${version}_all.deb" jenkins.deb
      sudo dpkg -i jenkins.deb

      sudo systemctl daemon-reload
      sudo systemctl enable jenkins
      sudo systemctl start jenkins
    elif [ -x "$(command -v rpm)" ]; then
      if [ -x "$(command -v dnf)" ]; then
        # fedora
        if [ "$download_java" ]; then
          sudo dnf install --assumeyes "java-$download_java-openjdk"-y
          sudo alternatives --set java "$(sudo update-alternatives --list java | grep "java-$download_java-openjdk")"
        fi

        sudo dnf upgrade
        sudo dnf install --assumeyes fontconfig
      elif [ -x "$(command -v yum)" ]; then
        # red hat
        if [ "$download_java" ]; then
          sudo yum -y install "java-$download_java-openjdk" -y
          sudo alternatives --set java "$(sudo alternatives --list java | grep "java-$download_java-openjdk")"
        fi

        sudo yum upgrade
        sudo -y yum install fontconfig
      fi

      download "https://github.com/jenkinsci/jenkins/releases/download/jenkins-$version/jenkins-$version-1.1.noarch.rpm" jenkins.noarch.rpm
      sudo rpm -i jenkins.noarch.rpm

      sudo systemctl daemon-reload
      sudo systemctl enable jenkins
      sudo systemctl start jenkins
    else
      download_jenkins_generic_linux
    fi
  fi
elif [ "$os" == "mac" ]; then
  if [ ! -x "$(command -v brew)" ]; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  mac_jenkins="jenkins-lts"
  if [ "$version" == "unstable" ] || [ "$version" == "$unstable_version" ]; then
    mac_jenkins="jenkins"
  fi

  brew install "$mac_jenkins"
  brew services start "$mac_jenkins"
elif [ "$os" == "win" ]; then
  if [ "$version" == "lts" ] || [ "$version" == "$stable_version" ]; then
    download "https://2.mirrors.in.sahilister.net/jenkins/windows-stable/$stable_version/jenkins.msi"
  elif [ "$version" == "unstable" ] || [ "$version" == "$unstable_version" ]; then
    download "https://2.mirrors.in.sahilister.net/jenkins/windows/$unstable_version/jenkins.msi"
  else
    download "https://github.com/jenkinsci/jenkins/releases/download/jenkins-$version/jenkins.msi"
  fi

  msiexec /i jenkins.msi
fi

echo "Installation completed"
