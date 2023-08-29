import paramiko
import time
import logging

logging.basicConfig(filename='deployment_log.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def ssh_execute(hostname, port, username, key_filename, commands):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(hostname, port, username, key_filename=key_filename)

    for command in commands:
        logging.info(f"Executing {command} on {hostname}")
        try:
            stdin, stdout, stderr = client.exec_command(command)
            output = stdout.read().decode()
            errors = stderr.read().decode()

            if output:
                logging.info(f"[{hostname}] Output: {output}")
            if errors:
                logging.error(f"[{hostname}] Error: {errors}")
                print(f"Error executing {command} on {hostname}. Check the log for details.")
        except Exception as e:
            logging.error(f"Failed to execute command on {hostname}. Reason: {str(e)}")
            print(f"Execution failed on {hostname}. Check the log for details.")

    client.close()

def run_on_centos7():
    commands = [
        'sudo yum update -y',
        'sudo yum install -y httpd mod_ssl python-certbot-apache',
        'sudo systemctl stop httpd',
        'certbot renew --dry-run',  
        'sudo systemctl start httpd'
    ]
    ssh_execute('centos7_ip', 22, 'apache', 'path_to_private_key_for_centos7', commands)

def run_on_ubuntu():
    commands = [
        'sudo apt update && sudo apt upgrade -y',
        'sudo apt install -y mariadb-server',
        'sudo systemctl enable mariadb',
        'sudo mysqladmin -u root password "newpassword"'
    ]
    ssh_execute('ubuntu_ip', 22, 'ubuntu_user', 'path_to_private_key_for_ubuntu', commands)

def run_on_alpine():
    commands = [
        'sudo apk update && sudo apk upgrade',
        'sudo apk add docker',
        'sudo service docker start',
        'sudo docker run hello-world'
    ]
    ssh_execute('alpine_ip', 22, 'alpine_user', 'path_to_private_key_for_alpine', commands)

if __name__ == "__main__":
    while True:
        current_time = time.localtime()
        if current_time.tm_hour == 6:  
            run_on_centos7()
            run_on_ubuntu()
            run_on_alpine()
            logging.info("Completed tasks for all systems.")
            time.sleep(3600)  
