#!/bin/bash

cd /etc/cloud/cloud.cfg.d
touch cloud-config.cfg
echo "" >cloud-config.cfg
echo "#cloud-config" >>cloud-config.cfg
echo "cloud_final_modules:" >>cloud-config.cfg
echo "- [scripts-user, always]" >>cloud-config.cfg

echo -e "$(date +'%Y-%m-%d %R') Sart machine" >>/home/ubuntu/test_log
echo -e "$(dig +short myip.opendns.com @resolver1.opendns.com) " >>/home/ubuntu/test_log
