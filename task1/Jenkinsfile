pipeline {
    agent any

    environment {
        SSH_DIR = "/var/lib/jenkins/.ssh"
    }

    stages {
        stage('Initialization') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/zinougeh/zino_sec_comp_take_home.git']]
                ])
            }
        }

        stage('Preparation') {
            steps {
                script {
                    if (!fileExists('task1/microk8s/ansible.yml')) {
                        error("ansible.yml is missing in the task1/microk8s directory!")
                    }
                }
            }
        }

        stage('AWS Infra Deployment via Terraform') {
            steps {
                deployInfrastructure()
            }
        }

        stage('Ensure EC2 SSH-ready') {
            steps {
                waitForSshReady()
            }
        }

        stage('Setup Jenkins User on Target Host') {
            steps {
                setupJenkinsUser()
            }
        }

        stage('Ansible Configures MicroK8s on EC2') {
            steps {
                setupMicroK8s()
            }
        }

        stage('Helm SonarQube on MicroK8s Deployment') {
            steps {
                deploySonarQube()
            }
        }
    }

    post {
        always {
            deleteDir()
        }
        success {
            echo "Deployment completed successfully."
        }
        failure {
            echo "Deployment failed! Please check the logs for more information."
        }
    }
}

def deployInfrastructure() {
    withCredentials([
        [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS_Access', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
        sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')
    ]) {
        dir('task1/terraform') {
            sh 'terraform init'
            sh "terraform apply -auto-approve -var=\"ssh_public_key=\$(cat ${SSH_KEY_PATH}.pub)\""
            env.EC2_PUBLIC_IP = sh(script: 'terraform output instance_public_ip', returnStdout: true).trim()
        }
    }
}

def waitForSshReady() {
    withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
        script {
            def maxAttempts = 30
            def attempts = 0
            while (attempts < maxAttempts) {
                def retVal = sh(script: "ssh -i ${SSH_DIR}/id_rsa.pem -o StrictHostKeyChecking=no -o ConnectionAttempts=1 ubuntu@${env.EC2_PUBLIC_IP} 'echo SSH_READY'", returnStatus: true)
                if (retVal == 0) {
                    break
                }
                sleep(time: 10, unit: 'SECONDS')
                attempts++
            }
            if (attempts == maxAttempts) {
                error("Failed to establish SSH connection after 30 attempts.")
            }
        }
    }
}

def setupJenkinsUser() {
    withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
        sh """
            ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem ubuntu@${env.EC2_PUBLIC_IP} "sudo useradd -m jenkins || echo 'Jenkins user already exists'"
            ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem ubuntu@${env.EC2_PUBLIC_IP} "sudo mkdir -p /home/jenkins/.ssh && echo \$(cat ${SSH_KEY_PATH}.pub) | sudo tee /home/jenkins/.ssh/authorized_keys > /dev/null"
        """
    }
}

def setupMicroK8s() {
    withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
        dir('task1/microk8s') {
            sh """
                scp -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem ansible.yml jenkins@${env.EC2_PUBLIC_IP}:/tmp
                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem jenkins@${env.EC2_PUBLIC_IP} "ansible-playbook /tmp/ansible.yml"
            """
        }
    }
}

def deploySonarQube() {
    withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
        dir('task1/sonar') {
            sh """
                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem jenkins@${env.EC2_PUBLIC_IP} "microk8s helm3 repo add sonarqube https://charts.helm.sh/stable"
                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem jenkins@${env.EC2_PUBLIC_IP} "microk8s helm3 repo update"
                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem jenkins@${env.EC2_PUBLIC_IP} "microk8s helm3 install sonar sonarqube/sonarqube -f values.yaml"
            """
        }
    }
}
