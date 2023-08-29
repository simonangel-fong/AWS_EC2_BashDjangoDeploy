#!/bin/bash
#Program Name: deploy.sh
#Author name: Wenhao Fang
#Date Created: Aug 23rd 2023
#Date updated:
#Description of the script: Sets up configuration for deployment.

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

###########################################################
## Update OS
###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Linux packages update start..."
update_os
echo -e "$(date +'%Y-%m-%d %R') Linux packages update completed.\n"

# ###########################################################
# ## Install and configure MySQL
# ###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') MySQL Installation and configuration start ..."
setup_mysql $P_USER $P_PWD $P_DB_NAME
echo -e "$(date +'%Y-%m-%d %R') MySQL Installation and configuration completed.\n"

# ###########################################################
# ## Establish virtual environment
# ###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Establish virtual environment start ..."
setup_venv
echo -e "$(date +'%Y-%m-%d %R') Establish virtual environment completed.\n"

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
    test_app $P_PROJECT_NAME
    echo -e "$(date +'%Y-%m-%d %R') Testing completed.\n"
else
    echo -e "$(date +'%Y-%m-%d %R') Testing skip.\n"
fi

# ###########################################################
# ## Install and configure Gunicorn
# ###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Install and configure Gunicorn start ..."
setup_gunicorn $P_PROJECT_NAME
echo -e "$(date +'%Y-%m-%d %R') Install and configure Gunicorn completed.\n"

# ###########################################################
# ## Install and configure Nginx
# ###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Install and configure Nginx start ..."
setup_nginx $P_PROJECT_NAME $P_HOST_IP
echo -e "$(date +'%Y-%m-%d %R') Install and configure Nginx completed.\n"

# ###########################################################
# ## Install and configure Supervisor
# ###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Install and configure Supervisor start ..."
setup_supervisor $P_PROJECT_NAME
echo -e "$(date +'%Y-%m-%d %R') Install and configure Supervisor completed.\n"

# ###########################################################
# ## Firewall configuration for production
# ###########################################################
is_continue "Firewall configuration" -1
P_INPUT=$?

if [ $P_INPUT == 1 ]; then
    echo -e "\n$(date +'%Y-%m-%d %R') Firewall configuration start ..."
    setup_firewall
    echo -e "$(date +'%Y-%m-%d %R') Firewall configuration completed.\n"
else
    echo -e "$(date +'%Y-%m-%d %R') Firewall configuration cancel."
fi

# ###########################################################
# ## Setup completed
# ###########################################################
echo -e "\n$(date +'%Y-%m-%d %R') Setup completed. \n"
read -p "Press Enter to continue..."
# clear
