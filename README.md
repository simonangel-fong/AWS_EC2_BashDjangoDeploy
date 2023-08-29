# Bash Deploy Django App

A project of bash script to deploy a django on an AWS EC2

---

## Deploy

- Step:

1. Create an EC2 instance

2. Connect to EC2 instance using Cloudshell

3. Load bash script to `~` path of instance

```sh
# change path
cd ~

# load script from github
git clone https://github.com/simonangel-fong/bash-deploy-django.git
```

4. Change path and run `delpoy.sh` script

```sh
# change path
cd bash-deploy-django

# run script
source script/deploy.sh
```

5. Input project data:
   
   - **Project name**: The name of django project.(Git repository name should be the same as django project name.)
   - **Git url**: The Url of Git repository.
   - **Host IP**: The public ip of EC2
   - **Username**: The name of new user to be created in mysql.
   - **Password**: The password of new user in mysql.
   - **Database name**: The name of database to be created in mysql
   - **Whether to test**: Optional
     - Enter "1": Script will run `runserver` in virtual environment to test django app on the port 8000 of public IP.
     - Otherwise, the test will be skipped.

6. Django project will be deployed on EC2 public IP .

- *It is available only with `http`. `https` need further configuration.
- **Firewall configuration is optional. 

---

## Update

- To update codes from github after deployment, run `update.sh` script and input project data as above.

```sh
# change path
cd ~
cd bash-deploy-django

# run script
source script/update.sh

```

---

## Example

- Deploy a demo django app using bash script. (Github: https://github.com/simonangel-fong/demoProj.git)

1. Download and run script

   ![download script](./pic/download_script.png)

2. Input project data

   ![input project data](./pic/input_project_data.png)

3. Testing app

   ![testing app](./pic/testing01.png)

   ![testing app](./pic/testing02.png)

4. Firewall configuration is optional

   ![firewall](./pic/firewall.png)

5. The final outcome:

    ![deployed](./pic/web.png)