#!/bin/bash
#Program Name: update.sh
#Author name: Wenhao Fang
#Date Created: Aug 27th 2023
#Date updated:
#Description of the script: Update codes and deploy

. ./func.sh # refer function file

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

# ###########################################################
# ## Download codes from github
# ###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Download codes from github start ..."
load_code $P_PROJECT_NAME $P_GITHUB_URL
echo -e "$(date +'%Y-%m-%d %R') Download codes from github completed.\n"

# ###########################################################
# ## Create .env file within project dir
# ###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Create .env file start ..."
create_env_file $P_PROJECT_NAME $P_HOST_IP $P_DB_NAME $P_USER $P_PWD 
echo -e "$(date +'%Y-%m-%d %R') Create .env file completed.\n"

# ###########################################################
# ## Install packages within venv
# ###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Install packages start ..."
update_venv_package $P_PROJECT_NAME
echo -e "$(date +'%Y-%m-%d %R') Install packages completed.\n"

# ###########################################################
# ## Migrate and test app on 8000
# ###########################################################
if [ $P_IS_TEST == 1 ]; then
    echo -e "\n$(date +'%Y-%m-%d %R') Testing start ..."
    test_app $P_PROJECT_NAME $P_MIGRATE_APP
    echo -e "$(date +'%Y-%m-%d %R') Testing completed.\n"
else
    echo -e "$(date +'%Y-%m-%d %R') Testing cancel.\n"
fi

###########################################################
## Reload supervisor and nginx
###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Reload supervisor"
sudo service supervisor reload # reload supervisor

echo -e "$(date +'%Y-%m-%d %R') Reload nginx"
sudo service nginx reload # relaod nginx

###########################################################
## Update completed
###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Update completed. \n"
read -p "Press Enter to continue..."
# clear
