#!/bin/bash
#Program Name: script.sh
#Author name: Wenhao Fang
#Date Created: Aug 30th 2023
#Date updated: Aug 30th 2023
#Description of the script: Sets up EC2 to deploy django app using user data.

## Updates Linux package
update_os() {
    echo -e "$(date +'%Y-%m-%d %R') Update Linux package starts..."
    DEBIAN_FRONTEND=noninteractive apt-get -y update # update the package on Linux system.
    # DEBIAN_FRONTEND=noninteractive apt-get -y upgrade # downloads and installs the updates for each outdated package and dependency
    echo -e "$(date +'%Y-%m-%d %R') Updating Linux package completed.\n"
}

## Install and configure MySQL
setup_mysql() {

    P_USER=$1
    P_PWD=$2
    P_DB_NAME=$3

    # Install MySQL
    echo -e "$(date +'%Y-%m-%d %R') Install mysql-server starts..."
    DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server
    systemctl start mysql
    echo -e "$(date +'%Y-%m-%d %R') Install mysql-server completed.\n"

    # Install MySQL related package
    echo -e "$(date +'%Y-%m-%d %R') Install MySQL related package starts..."
    DEBIAN_FRONTEND=noninteractive apt-get -y install python3-dev default-libmysqlclient-dev build-essential pkg-config
    systemctl restart mysql
    echo -e "$(date +'%Y-%m-%d %R') Install MySQL related package completed.\n"

    # logging mysql status
    echo -e "\n$(date +'%Y-%m-%d %R') Mysql status:" >>/home/ubuntu/setup_log
    systemctl status mysql.service >>/home/ubuntu/setup_log

    # Create database
    echo -e "$(date +'%Y-%m-%d %R') Create project database starts..."
    mysql -u root -e "CREATE USER IF NOT EXISTS '${P_USER}'@'localhost' IDENTIFIED BY '${P_PWD}';"
    mysql -u root -e "GRANT CREATE, ALTER, DROP, INSERT, UPDATE, INDEX, DELETE, SELECT, REFERENCES, RELOAD on *.* TO '${P_USER}'@'localhost' WITH GRANT OPTION;"
    mysql -u root -e "FLUSH PRIVILEGES;"
    mysql -u$P_USER -p$P_PWD -e "CREATE DATABASE IF NOT EXISTS ${P_DB_NAME};"
    echo -e "$(date +'%Y-%m-%d %R') Create project database completed.\n"

    # logging database
    echo -e "\n$(date +'%Y-%m-%d %R') Databases in Mysql:" >>/home/ubuntu/setup_log
    mysql -u$P_USER -p$P_PWD -e "show databases;" >>/home/ubuntu/setup_log
}

## Establish virtual environment
setup_venv() {
    echo -e "$(date +'%Y-%m-%d %R') Install virtual environment package starts..."
    DEBIAN_FRONTEND=noninteractive apt-get -y install python3-venv # Install pip package
    # DEBIAN_FRONTEND=noninteractive apt-get -y install virtualenv # Install pip package
    echo -e "$(date +'%Y-%m-%d %R') Install virtual environment package completed.\n"

    echo -e "$(date +'%Y-%m-%d %R') Create Virtual environment starts..."
    rm -rf /home/ubuntu/env          # remove existing venv
    python3 -m venv /home/ubuntu/env # Creates virtual environment
    echo -e "$(date +'%Y-%m-%d %R') Create Virtual environment completed.\n"
}

## Download codes from github
load_code() {

    P_REPO_NAME=$1
    P_GITHUB_URL=$2

    echo -e "$(date +'%Y-%m-%d %R') Download codes from github starts..."
    rm -rf /home/ubuntu/${P_REPO_NAME} # remove the exsting directory
    cd /home/ubuntu
    git clone $P_GITHUB_URL # clone codes from github
    echo -e "$(date +'%Y-%m-%d %R') Download codes from github completed.\n"
}

## Create .env file within project dir
create_env_file() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2
    P_HOST_IP=$3
    P_DB_NAME=$4
    P_USER=$5
    P_PWD=$6

    echo -e "$(date +'%Y-%m-%d %R') Create .env file starts..."
    env_file=/home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}/${P_PROJECT_NAME}/.env
    cat >$env_file <<ENV
DEBUG=False
ALLOWED_HOSTS=${P_HOST_IP}
MYSQL_DATABASE_NAME=${P_DB_NAME}
MYSQL_USERNAME=${P_USER}
MYSQL_PASSWORD=${P_PWD}
MYSQL_HOST=localhost
MYSQL_PORT=3306
ENV
    echo -e "$(date +'%Y-%m-%d %R') Create .env file completed.\n"

}

## Update packages within venv
update_venv_package() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2

    echo -e "$(date +'%Y-%m-%d %R') Update venv packages starts..."
    source /home/ubuntu/env/bin/activate # activate venv

    pip install -r /home/ubuntu/${P_REPO_NAME}/requirements.txt
    echo -e "$(date +'%Y-%m-%d %R') Update venv packages completed.\n"

    # logging package list
    echo -e "\n$(date +'%Y-%m-%d %R') Pip list:" >>/home/ubuntu/setup_log
    pip list >>/home/ubuntu/setup_log

    # Migrate App
    echo -e "$(date +'%Y-%m-%d %R') Migrate App starts..."
    python3 /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}/manage.py makemigrations
    python3 /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}/manage.py migrate
    deactivate
    echo -e "$(date +'%Y-%m-%d %R') Migrate App starts completed.\n"
}

## Install and configure Gunicorn
setup_gunicorn() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2

    #  Install gunicorn in venv
    echo -e "$(date +'%Y-%m-%d %R') Install gunicorn starts..."
    source /home/ubuntu/env/bin/activate # activate venv
    pip install gunicorn                 # install gunicorn
    deactivate                           # deactivate venv
    echo -e "$(date +'%Y-%m-%d %R') Install gunicorn completed.\n"

    # Configuration gunicorn.socket
    socket_conf=/etc/systemd/system/gunicorn.socket

    cat >$socket_conf <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK
    echo -e "$(date +'%Y-%m-%d %R') gunicorn.socket created."

    # Configuration gunicorn.service
    service_conf=/etc/systemd/system/gunicorn.service

    cat >$service_conf <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=/home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    ${P_PROJECT_NAME}.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE
    echo -e "$(date +'%Y-%m-%d %R') gunicorn.socket created."

    # Apply gunicorn configuration
    echo -e "$(date +'%Y-%m-%d %R') gunicorn restart.\n"
    systemctl daemon-reload          # reload daemon
    systemctl start gunicorn.socket  # Start gunicorn
    systemctl enable gunicorn.socket # enable on boots
    systemctl restart gunicorn       # restart gunicorn

    # logging gunicorn status
    echo -e "$(date +'%Y-%m-%d %R') gunicorn.socket status:" >>/home/ubuntu/setup_log
    systemctl status gunicorn.socket >>/home/ubuntu/setup_log
}

## Install and configure Nginx
setup_nginx() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2
    P_HOST_IP=$3

    # Install nginx
    echo -e "$(date +'%Y-%m-%d %R') Install nginx starts."
    DEBIAN_FRONTEND=noninteractive apt-get -y install nginx # install nginx
    echo -e "$(date +'%Y-%m-%d %R') Install nginx completed.\n"

    # overwrites user
    echo -e "$(date +'%Y-%m-%d %R') Overwrite nginx.conf."
    nginx_conf=/etc/nginx/nginx.conf
    sed -i '1cuser root;' $nginx_conf

    # create conf file
    echo -e "$(date +'%Y-%m-%d %R') Create conf file."
    django_conf=/etc/nginx/sites-available/django.conf
    cat >$django_conf <<DJANGO_CONF
server {
listen 80;
server_name ${P_HOST_IP};
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME};
}

location /media/ {
    root /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME};
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF

    #  Creat link in sites-enabled directory
    echo -e "$(date +'%Y-%m-%d %R') Create link in sites-enabled."
    ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled

    # restart nginx
    echo -e "$(date +'%Y-%m-%d %R') Nginx restart."
    systemctl restart nginx

    # logging nginx status
    echo -e "\n$(date +'%Y-%m-%d %R') Nginx syntax:" >>/home/ubuntu/setup_log
    nginx -t >>/home/ubuntu/setup_log

    echo -e "\n$(date +'%Y-%m-%d %R') Nginx status:" >>/home/ubuntu/setup_log
    systemctl daemon-reload # reload daemon
    systemctl status nginx >>/home/ubuntu/setup_log
}

## Reload Nginx
reload_nginx() {
    # relaod nginx
    systemctl daemon-reload # reload daemon
    systemctl reload nginx  # reload nginx

    # logging nginx status
    echo -e "\n$(date +'%Y-%m-%d %R') Nginx reload syntax:" >>/home/ubuntu/setup_log
    nginx -t >>/home/ubuntu/setup_log

    echo -e "\n$(date +'%Y-%m-%d %R') Nginx reload status:" >>/home/ubuntu/setup_log
    systemctl status nginx >>/home/ubuntu/setup_log
}

## Install and configure Supervisor
setup_supervisor() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2

    # Install supervisor
    echo -e "$(date +'%Y-%m-%d %R') Install supervisor starts."
    DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor # install supervisor
    echo -e "$(date +'%Y-%m-%d %R') Install supervisor completed.\n"

    # create directory for echo -e
    mkdir -p /var/log/gunicorn

    echo -e "$(date +'%Y-%m-%d %R') Create gunicorn.conf."
    supervisor_gunicorn=/etc/supervisor/conf.d/gunicorn.conf # create configuration file
    cat >$supervisor_gunicorn <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  ${P_PROJECT_NAME}.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN

    # Apply configuration.
    echo -e "$(date +'%Y-%m-%d %R') Reload supervisor."
    supervisorctl reread # tell supervisor read configuration file >> /home/ubuntu/setup_log
    supervisorctl update # update supervisor configuration
    systemctl daemon-reload
    supervisorctl reload # Restarted supervisord

    # logging supervisor status
    sleep 5
    echo -e "\n$(date +'%Y-%m-%d %R') Supervisor status:" >>/home/ubuntu/setup_log
    supervisorctl status >>/home/ubuntu/setup_log
}

## Reload Supervisor
reload_supervisor() {
    # relaod supervisor
    systemctl daemon-reload     # reload daemon
    systemctl reload supervisor # reload supervisor

    # logging supervisor status
    sleep 5
    echo -e "\n$(date +'%Y-%m-%d %R') Supervisor status:" >>/home/ubuntu/setup_log
    supervisorctl status >>/home/ubuntu/setup_log
}

## Create update script
create_update_script() {

    echo -e "$(date +'%Y-%m-%d %R') Update script file creates."
    rm -f /home/ubuntu/update.sh
    update_script=/home/ubuntu/update.sh # create update script file
    cat >$update_script <<UPDATE_SCRIPT
#!/bin/bash
#Program Name: update.sh
#Author name: Wenhao Fang
#Date Created: Aug 27th 2023
#Date updated:
#Description of the script: Update codes and deploy


## Download codes from github
load_code() {

    P_REPO_NAME=$1
    P_GITHUB_URL=$2

    echo -e "$(date +'%Y-%m-%d %R') Download codes from github starts..."
    rm -rf /home/ubuntu/${P_REPO_NAME} # remove the exsting directory
    cd /home/ubuntu
    git clone $P_GITHUB_URL # clone codes from github
    echo -e "$(date +'%Y-%m-%d %R') Download codes from github completed.\n"
}

## Create .env file within project dir
create_env_file() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2
    P_HOST_IP=$3
    P_DB_NAME=$4
    P_USER=$5
    P_PWD=$6

    echo -e "$(date +'%Y-%m-%d %R') Create .env file starts..."
    env_file=/home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}/${P_PROJECT_NAME}/.env
    cat >$env_file <<ENV
DEBUG=False
ALLOWED_HOSTS=${P_HOST_IP}
MYSQL_DATABASE_NAME=${P_DB_NAME}
MYSQL_USERNAME=${P_USER}
MYSQL_PASSWORD=${P_PWD}
MYSQL_HOST=localhost
MYSQL_PORT=3306
ENV
    echo -e "$(date +'%Y-%m-%d %R') Create .env file completed.\n"

}

## Update packages within venv
update_venv_package() {

    P_REPO_NAME=$1
    P_PROJECT_NAME=$2

    echo -e "$(date +'%Y-%m-%d %R') Update venv packages starts..."
    source /home/ubuntu/env/bin/activate # activate venv

    pip install -r /home/ubuntu/${P_REPO_NAME}/requirements.txt
    echo -e "$(date +'%Y-%m-%d %R') Update venv packages completed.\n"

    # logging package list
    echo -e "\n$(date +'%Y-%m-%d %R') Pip list:" >>/home/ubuntu/update_log
    pip list >>/home/ubuntu/update_log

    # Migrate App
    echo -e "$(date +'%Y-%m-%d %R') Migrate App starts..."
    python3 /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}/manage.py makemigrations
    python3 /home/ubuntu/${P_REPO_NAME}/${P_PROJECT_NAME}/manage.py migrate
    deactivate
    echo -e "$(date +'%Y-%m-%d %R') Migrate App starts completed.\n"
}

## Reload Nginx
reload_nginx() {
    # relaod nginx
    systemctl daemon-reload # reload daemon
    systemctl reload nginx  # reload nginx

    # logging nginx status
    echo -e "\n$(date +'%Y-%m-%d %R') Nginx reload syntax:" >>/home/ubuntu/update_log
    nginx -t >>/home/ubuntu/update_log

    echo -e "\n$(date +'%Y-%m-%d %R') Nginx reload status:" >>/home/ubuntu/update_log
    systemctl status nginx >>/home/ubuntu/update_log
}

## Reload Supervisor
reload_supervisor() {
    # relaod supervisor
    systemctl daemon-reload     # reload daemon
    systemctl reload supervisor # reload supervisor

    # logging supervisor status
    sleep 5
    echo -e "\n$(date +'%Y-%m-%d %R') Supervisor status:" >>/home/ubuntu/update_log
    supervisorctl status >>/home/ubuntu/update_log
}

echo -e "\n$(date +'%Y-%m-%d %R') The name of github repository:"
read P_REPO_NAME

echo -e "\n$(date +'%Y-%m-%d %R') The name of django project:"
read P_PROJECT_NAME

echo -e "\n$(date +'%Y-%m-%d %R') The URL of github:"
read P_GITHUB_URL

P_HOST_IP=$(dig +short myip.opendns.com @resolver1.opendns.com) # public ip

echo -e "\n$(date +'%Y-%m-%d %R') The username for MySQL:"
read P_USER

echo -e "\n$(date +'%Y-%m-%d %R') The password for MySQL:"
read -s P_PWD

echo -e "\n$(date +'%Y-%m-%d %R') The name of batabase for app project:"
read P_DB_NAME

## Download codes from github
load_code $P_REPO_NAME $P_GITHUB_URL

## Create .env file within project dir
create_env_file $P_REPO_NAME $P_PROJECT_NAME $P_HOST_IP $P_DB_NAME $P_USER $P_PWD

## Install packages within venv
update_venv_package $P_REPO_NAME $P_PROJECT_NAME

## Reload Nginx
reload_nginx

## Reload Supervisor
reload_supervisor
UPDATE_SCRIPT

}

create_cloud_config() {

    echo -e "$(date +'%Y-%m-%d %R') Create cloud config for restart script."
    cloud_config=/etc/cloud/cloud.cfg.d/cloud-config.cfg # create cloud configuration file
    cat >$cloud_config <<CLOUD_CONFIG
#cloud-config
cloud_final_modules:
- [scripts-user, always]
CLOUD_CONFIG
}

P_REPO_NAME="demoProj"
P_PROJECT_NAME="demoProj"
P_GITHUB_URL="https://github.com/simonangel-fong/demoProj.git"
P_HOST_IP=$(dig +short myip.opendns.com @resolver1.opendns.com) # public ip
P_USER="adam"
P_PWD="adam123456"
P_DB_NAME="django"

## Update OS
update_os

## Install and configure MySQL
setup_mysql $P_USER $P_PWD $P_DB_NAME

## Establish virtual environment
setup_venv

## Download codes from github
load_code $P_REPO_NAME $P_GITHUB_URL

## Create .env file within project dir
create_env_file $P_REPO_NAME $P_PROJECT_NAME $P_HOST_IP $P_DB_NAME $P_USER $P_PWD

## Install packages within venv
update_venv_package $P_REPO_NAME $P_PROJECT_NAME

## Install and configure Gunicorn
setup_gunicorn $P_REPO_NAME $P_PROJECT_NAME

## Install and configure Nginx
setup_nginx $P_REPO_NAME $P_PROJECT_NAME $P_HOST_IP

## Install and configure Supervisor
setup_supervisor $P_REPO_NAME $P_PROJECT_NAME

## Create update script
create_update_script

## Create cloud config, the script will be run each restart.
create_cloud_config
