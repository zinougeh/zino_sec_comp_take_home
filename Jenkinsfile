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
                sh 'pwd'
                sh 'ls -al'
                script {
                    if (!fileExists('task1/microk8s/ansible.yml')) {
                        error("ansible.yml is missing in the task1/microk8s directory!")
                    }
                }
            }
        }

        stage('AWS Infra Deployment via terraform') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS_Access', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
                    sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')
                ]) {
                    dir('task1/terraform') {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve -var="ssh_public_key=$(cat ${SSH_KEY_PATH}.pub)"'
                        script {
                            env.EC2_PUBLIC_IP = sh(script: 'terraform output instance_public_ip', returnStdout: true).trim()
                            env.EC2_PUBLIC_DNS = sh(script: 'terraform output instance_public_dns', returnStdout: true).trim()
                        }
                    }
                }
            }
        }

        stage('Ensure EC2 SSH-ready') {
            steps {
                echo "Ensuring the EC2 instance is ready for SSH connections..."
                retry(10) {
                    script {
                        def result = sh(script: "ssh -o StrictHostKeyChecking=no -i ${SSH_DIR}/id_rsa.pem -o ConnectionAttempts=1 ubuntu@${env.EC2_PUBLIC_IP} 'echo SSH_READY'", returnStatus: true)
                        if (result != 0) {
                            error("Failed to connect via SSH. Retrying...")
                        }
                    }
                }
            }
        }

        stage('Setup Jenkins User on Target Host') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
                        def userExists = sh(script: "ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem ubuntu@${env.EC2_PUBLIC_IP} 'getent passwd jenkins'", returnStatus: true)

                        if (userExists != 0) {
                            sh """
                                # Creating the jenkins user with default shell as /bin/bash
                                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem ubuntu@${env.EC2_PUBLIC_IP} "sudo useradd jenkins -m -s /bin/bash"
                                
                                # Granting the jenkins user sudo privileges
                                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem ubuntu@${env.EC2_PUBLIC_IP} "echo 'jenkins ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers"

                                # Setting up the SSH directory for the jenkins user
                                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem ubuntu@${env.EC2_PUBLIC_IP} "sudo mkdir -p /home/jenkins/.ssh && sudo chown jenkins:jenkins /home/jenkins/.ssh && sudo chmod 700 /home/jenkins/.ssh"
                            """
                        }
                        
                        sh """
                            # Copying the SSH public key
                            scp -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem $SSH_DIR/id_rsa.pub ubuntu@${env.EC2_PUBLIC_IP}:/home/ubuntu/id_rsa.pub
                            ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem ubuntu@${env.EC2_PUBLIC_IP} "sudo mv /home/ubuntu/id_rsa.pub /home/jenkins/.ssh/authorized_keys && sudo chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys && sudo chmod 600 /home/jenkins/.ssh/authorized_keys"
                        """
                    }
                }
            }
        }

        stage('Ansible Configures MicroK8s on EC2') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
                        dir('task1/microk8s') {
                            sh """
                                mkdir -p $SSH_DIR
                                cp ${SSH_KEY_PATH} $SSH_DIR/id_rsa.pem
                                chmod 600 $SSH_DIR/id_rsa.pem
                            """

                            writeFile file: 'ansible-ssh.cfg', text: """
                                Host *
                                    StrictHostKeyChecking no
                                    IdentityFile ${SSH_DIR}/id_rsa.pem
                                    UserKnownHostsFile /dev/null
                            """

                            retry(3) {
                                sh "ANSIBLE_SSH_ARGS='-F ansible-ssh.cfg' ansible-playbook -i ${env.EC2_PUBLIC_IP}, -u jenkins ansible.yml"
                            }
                        }
                    }
                }
            }
        }

        stage('Setup Dependencies') {
            steps {
                // Ensure kubectl is installed
                sh '''
                    if ! command -v kubectl &> /dev/null; then
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        sudo mv kubectl /usr/local/bin/
                    fi
                '''
            }
        }

        stage('Deploy SonarQube with Helm') {
            steps {
                sh 'helm repo add sonarqube https://helm.sonarqube.org'
                sh 'helm repo update'
                sh 'helm install sonarqube sonarqube/sonarqube --set service.type=LoadBalancer'
                sh 'kubectl rollout status deploy/sonarqube-sonarqube'
                sh 'kubectl get all'
            }
        }

        stage('Post-Deployment Steps') {
            steps {
                echo 'Do any post-deployment steps here'
            }
        }
    }

    post {
        always {
            sh 'echo "This will always run"'
            // Clean-up any local resources or reset environment here
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}

void deploySonarQube() {
    // This is the logic for the sonarqube deployment
    sh '''
        helm repo add sonarqube https://helm.sonarqube.org
        helm repo update
        helm install sonarqube sonarqube/sonarqube --set service.type=LoadBalancer
        kubectl rollout status deploy/sonarqube-sonarqube
    '''
}
