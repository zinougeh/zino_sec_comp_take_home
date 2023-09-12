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
                        }
                    }
                }
            }
        }

        stage('Ensure EC2 SSH-ready') {
            steps {
                retry(10) {
                    sleep(time: 10, unit: 'SECONDS')
                    sh(script: "ssh -o StrictHostKeyChecking=no -i ${SSH_DIR}/id_rsa.pem -o ConnectionAttempts=1 ubuntu@${env.EC2_PUBLIC_IP} 'echo SSH_READY'", returnStatus: true)
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

        stage('Helm SonarQube on MicroK8s Deployment') {
            steps {
                deploySonarQube()
            }
        }
    }

    post {
        always {
            echo "Pipeline completed."
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

def deploySonarQube() {
    withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
        dir('task1/sonar') {
            sh """
                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem jenkins@${env.EC2_PUBLIC_IP} "microk8s helm3 repo add sonarqube https://charts.helm.sh/stable"
                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem jenkins@${env.EC2_PUBLIC_IP} "microk8s helm3 repo update"
                ssh -o StrictHostKeyChecking=no -i $SSH_DIR/id_rsa.pem jenkins@${env.EC2_PUBLIC_IP} "microk8s helm3 install sonar sonarqube -f values.yaml"
            """
        }
    }
}
