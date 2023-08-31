#!/bin/bash
#Program Name: update.sh
#Author name: Wenhao Fang
#Date Created: Aug 27th 2023
#Date updated: Aug 30th 2023
#Description of the script: Update codes and deploy

###########################################################
## Download codes from github
###########################################################
load_code() {

    P_PROJECT_NAME=$1
    P_GITHUB_URL=$2

    echo -e "$(date +'%Y-%m-%d %R') Download codes from github starts..."
    rm -rf /home/ubuntu/${P_PROJECT_NAME} # remove the exsting directory
    cd /home/ubuntu
    git clone $P_GITHUB_URL # clone codes from github
    echo -e "$(date +'%Y-%m-%d %R') Download codes from github completed.\n"

    # logging
    echo -e "\n$(date +'%Y-%m-%d %R') Code loaded." >>/home/ubuntu/update_log
}

###########################################################
## Create .env file within project dir
###########################################################
create_env_file() {

    P_PROJECT_NAME=$1
    P_HOST_IP=$2
    P_DB_NAME=$3
    P_USER=$4
    P_PWD=$5

    echo -e "$(date +'%Y-%m-%d %R') Create .env file starts..."
    env_file=/home/ubuntu/${P_PROJECT_NAME}/${P_PROJECT_NAME}/${P_PROJECT_NAME}/.env
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

    # logging
    echo -e "\n$(date +'%Y-%m-%d %R') Env file created." >>/home/ubuntu/update_log
}

###########################################################
## Update packages within venv
###########################################################
update_venv_package() {

    P_PROJECT_NAME=$1
    P_MIGRATE_APP=$2

    echo -e "$(date +'%Y-%m-%d %R') Update venv packages starts..."
    source /home/ubuntu/env/bin/activate # activate venv

    pip install -r /home/ubuntu/${P_PROJECT_NAME}/requirements.txt
    echo -e "$(date +'%Y-%m-%d %R') Update venv packages completed.\n"

    # logging package list
    echo -e "\n$(date +'%Y-%m-%d %R') Pip list:" >>/home/ubuntu/update_log
    pip list >>/home/ubuntu/update_log

    # Migrate App
    echo -e "$(date +'%Y-%m-%d %R') Migrate App starts..."
    python3 /home/ubuntu/${P_PROJECT_NAME}/${P_PROJECT_NAME}/manage.py makemigrations
    python3 /home/ubuntu/${P_PROJECT_NAME}/${P_PROJECT_NAME}/manage.py migrate
    deactivate
    echo -e "$(date +'%Y-%m-%d %R') Migrate App starts completed.\n"

    # logging
    echo -e "\n$(date +'%Y-%m-%d %R') Update env packages." >>/home/ubuntu/update_log
}

###########################################################
## Reload Nginx
###########################################################
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

###########################################################
## Reload Supervisor
###########################################################
reload_supervisor() {
    # relaod supervisor
    systemctl daemon-reload     # reload daemon
    systemctl reload supervisor # reload supervisor

    # logging supervisor status
    sleep 5
    echo -e "\n$(date +'%Y-%m-%d %R') Supervisor status:" >>/home/ubuntu/update_log
    supervisorctl status >>/home/ubuntu/update_log
}

echo -e "\n$(date +'%Y-%m-%d %R') The name of django project:"
read P_PROJECT_NAME

echo -e "\n$(date +'%Y-%m-%d %R') The URL of github:"
read P_GITHUB_URL

echo -e "\n$(date +'%Y-%m-%d %R') The IP to deploy:"
read P_HOST_IP

echo -e "\n$(date +'%Y-%m-%d %R') The username for MySQL:"
read P_USER

echo -e "\n$(date +'%Y-%m-%d %R') The password for MySQL:"
read -s P_PWD

echo -e "\n$(date +'%Y-%m-%d %R') The name of batabase for app project:"
read P_DB_NAME

echo -e "\n$(date +'%Y-%m-%d %R') You want to test your app during deployment?\nEnter '1' if you need to test."
read P_IS_TEST

## Download codes from github
load_code $P_PROJECT_NAME $P_GITHUB_URL

## Create .env file within project dir
create_env_file $P_PROJECT_NAME $P_HOST_IP $P_DB_NAME $P_USER $P_PWD

## Install packages within venv
update_venv_package $P_PROJECT_NAME

## Reload Nginx
reload_nginx

## Reload Supervisor
reload_supervisor
