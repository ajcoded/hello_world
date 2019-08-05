# HelloWorld Python API

HelloWOrld Python API runs on PORT:5000 to start the application set Environment Variable ENV_TYPE=dev & then use below command
python server.py


## Pre-requisites

1. Python Version 3.7
2. AWS & EB CLI should be installed for zero-downtime deployment
3. Terraform CLI should be installed for Infrastructure-as-a-code implementation =
4. AWS Creds must be stored in environment variable to reduce operational overhead
5. Environment Variable ENV_TYPE decides the nature of implementation to automate both local deployment as well as cloud

## IaaC
Terraform is used with aws provider to create a secure implementation where 1VPC, 2SUBNETS(1PRIVATE, 1PUBLIC), 1LOADBALANCER, 1EBS, 1RDS is created all the required Environment variables are set using different terraform strategies. All the Secrets are provided to environment in a very secure way.
Code Location : deployment/terraform/main.tf

## Application
App works with both local and cloud environment & doesn't require any manual changes for mode switch just single environment variable will be able to update mode of deployment. Triggering Application requires first pip install -r requirement.txt.
Once the dependencies are loaded in the environment we can trigger the app & can run testcases before running the actual app
Code Location: Hello_World/server.py

## Zero-Downtime Deployment
use shell script to create blue-green deployment using aws beanstalk provided rollingupdate feature. 
Below is the command which can be used to update the environment with new version of application :-
deploy.sh Application_NAME final_version ENV
It expects that all the authentication variables of AWS are already set in the environment & new artifacts are uploaded to a S3 bucket with credentials set in environment otherwise it'll be failed application name & Environment should match variables of terraform for the sake of common naming convention which will reduce overhead of creating new automation to find the desired environment

## Proposed Architecture pic uploaded
