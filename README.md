# Bash Deploy Django App

A project of bash script to deploy a django on an AWS EC2

## Deploy

- Step:

1. Create an EC2 instance

2. Connect to EC2 instance using Cloudshell

3. Load bash script to instance

```sh
git clone https://github.com/simonangel-fong/django_EC2_Bash.git
```

4. Run `delpoy.sh` script

```sh
source script/deploy.sh
```

5. Input project data:
   
   - **Project name**: The name of django project.(Git repository name should be the same as django project name.)
   - **Git url**: The Url of Git repository.
   - **Host IP**: The public ip of EC2
   - **Username**: The name of new user to be created in mysql.
   - **Password**: The password of new user in mysql.
   - **Database name**: The name of database to be created in mysql
   - **Whether to test**:
     - Enter "1": Script will run `runserver` in virtual environment to test django app on the port 8000 of public IP.
     - Otherwise, the test will be skipped.

6. Django project will be deployed on EC2 public IP .

- *It is available only with `http`. `https` need further configuration.
- **Firewall configuration is optional. 
