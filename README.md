# EKS deployment. 
This project support multi region and multi environmet.
Terraform  v0.14.4
PowerShell v5.1

* Set project environmen variables: 

  As example in file: env\dev\varprj.txt

* Get access to AWS  
```bash
aws sts get-session-token --serial-number arn:aws:iam::[AWS Account ID]:mfa/[User ID] --token-code   code-from-token
AWS configure --profile YourAwsProfile
```

* Initiate work environment

```bash
cd ./terraform
cd ./00_init
./terra.ps1 -action init -region us-west-2
./terra.ps1 -action apply -region us-west-2
```
This operation created AWS s3 backend and key pair in project folder .\secret and also file .\secret\varprivate.txt
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f CourseEKS-BNS-01-dev
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f CourseEKS-BNS-01-production
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f CourseEKS-BNS-01-staging
```
setup \secret\varprivate.txt
    REPO_NAME=["testimage-fe","testimage-be"]
    PROFILE="YourAwsProfile"
    INGRES_SCIDR_BLOCK=["195.216.214.01]"
    OWNER="YourName"

* Create aws eks. 
```bash
 cd ./terraform
./createterra.ps1 -action init 
./createterra.ps1 -action apply
```
This step will take around 15-20 minutes to complete.
By default, the script will create -environment dev -region us-west-2

* To interact with your cluster, run this command in your terminal:
```bash
aws eks --region us-west-2 update-kubeconfig --name eks-CourseEKS-BNS-dev-uswest2-kDJPt1Oi --profile mfa
```
* Destroy aws eks.
```bash
cd ./terraform
./createterra.ps1 -action destroy 
cd ./00_init
./terra.ps1 -action destroy -region us-west-2
```

https://learn.hashicorp.com/tutorials/terraform/eks
