# Documentation for jenkins task

### Setup Master-slave architecture
* Created two EC2 instances on Amazon AWS, namely Jenkins-master and Jenkins-slave.
* On Jenkins-master,
    * Installed Java 17 and jenkins through,
    ```sh
    sudo apt update
    sudo apt install openjdk-17-jre fontconfig jenkins
    ```
    * After installation, whitelisted inbound rule on port 8080 in AWS security for both machines.
    * After accesing jenkins on the machine ip and port, followed through the initial steps to complete the installation.
    * Created a new node/agent.
* On Jenkins-slave,
    * Ran the command provided for jenkins agent node installation on a screen.
* Master-slave installation completed.

### Setup Role based authorization
* Installed Role Based Authorization plugin.
* Create a role `read` with overall read permission.
* Created a item role `java` with regex `java-app` with read and build permission.
* Created a user `user2` and assigned roles `read` and `java`.

### Pipeline to execute shell script
* Created a shell script and pushed it to github.
* Written a pipeline that pulls the script through `git`.
* Adds execute permission to it.
* Runs the script.
* Installed and configured a plugin named `diskusage` that monitors the overall health of jenkins and storage and send a mail on 80% threshold.
* Configured the mailing smtp server.

##### Pipeline code
```groovy
pipeline {
    agent any

    stages {
        stage('Prepare') {
            steps {
                git url: 'https://github.com/AbhigyaKrishna/devops-sem-3', branch: 'main'
                sh 'chmod +x job.sh'
            }
        }
        
        stage('Run') {
            steps {
                sh './job.sh'
            }
        }
    }
}
```

### Java app
* Created a simple java application and pushed it to github.
* Wrote a pipeline script with triggers and parameters to run the pipeline.
* Configured `jdk` and `maven` tool for custom version.
* Configured github webhook to integrate with the pipeline.

##### Pipeline code
```groovy
pipeline {
    agent any

    tools {
        maven 'M3'
        jdk "jdk-21"
    }

    options {
        timeout time: 5, unit: 'MINUTES' 
    }
    
    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build.')
    }

    triggers {
        pollSCM 'H */4 * * *'
    }

    stages {
        stage('Prepare') {
            steps {
                git url: 'https://github.com/AbhigyaKrishna/SimpleJavaApp', branch: '${BRANCH}'
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        
        stage('Archive') {
            steps {
                archiveArtifacts 'target/*.jar'
            }
        }
    }
}
```