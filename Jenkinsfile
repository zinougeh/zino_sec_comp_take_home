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
                
                // Check for the presence of ansible.yml inside the microK8s directory
                script {
                    if (!fileExists('task1/micro8s/ansible.yml')) {
                        error("ansible.yml is missing in the task1/micro8s directory!")
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
                        sh 'terraform apply -auto-approve -var="ssh_public_key=$(cat $SSH_KEY_PATH.pub)"'
                        script {
                            env.EC2_PUBLIC_IP = sh(script: 'terraform output instance_public_ip', returnStdout: true).trim()
                        }
                    }
                }
            }
        }

        stage('Ensure EC2 SSH-ready') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
                    script {
                        for (int i = 0; i < 30; i++) {
                            def retVal = sh(script: "ssh -i ${SSH_DIR}/id_rsa.pem -o StrictHostKeyChecking=no -o ConnectionAttempts=1 ubuntu@${env.EC2_PUBLIC_IP} 'echo SSH_READY'", returnStatus: true)
                            if (retVal == 0) {
                                break
                            }
                            sleep(time: 10, unit: 'SECONDS')
                        }
                    }
                }
            }
        }

        stage('Ansible Configures MicroK8s on EC2') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
                        dir('task1/micro8s') {
                            sh 'mkdir -p $SSH_DIR'
                            sh "cp ${SSH_KEY_PATH} $SSH_DIR/id_rsa.pem"
                            sh "chmod 600 $SSH_DIR/id_rsa.pem"
                        
                            writeFile file: 'ansible-ssh.cfg', text: """
                                Host *
                                    StrictHostKeyChecking no
                                    IdentityFile ${SSH_DIR}/id_rsa.pem
                                    UserKnownHostsFile /dev/null
                            """
                        
                            def exists = fileExists('ansible.yml')
                            if (!exists) {
                                error "ansible.yml is missing in the task1/micro8s directory!"
                            }
                            
                            retry(3) {
                                sh "ANSIBLE_SSH_ARGS='-F ansible-ssh.cfg' ansible-playbook -i ${env.EC2_PUBLIC_IP}, -u ubuntu ansible.yml"
                            }
                        }
                    }
                }
            }
        }

        stage('Helm SonarQube on Micro8s Deployment') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'sec_com_ass_key_pair', keyFileVariable: 'SSH_KEY_PATH')]) {
                    dir('task1/sonar/sonarqube') {
                        script {
                            sh """
                                scp -o StrictHostKeyChecking=no -i "${SSH_DIR}/id_rsa.pem" -r sonarqube ubuntu@${env.EC2_PUBLIC_IP}:/tmp
                                ssh -o StrictHostKeyChecking=no -i "${SSH_DIR}/id_rsa.pem" ubuntu@${env.EC2_PUBLIC_IP} 'sudo microk8s helm install sonar /tmp/sonarqube && sudo microk8s helm ls'
                            """
                        }
                    }
                }
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
