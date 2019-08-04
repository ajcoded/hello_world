#!/bin/bash

set -x
shopt -s nocasematch

checkSuccessCode () {
  if [ ! -z "$1" ]; then
    echo $1
    if [ $1 != "0" ]; then
      exit 255;
    elif [[ $1 == *"ERROR"*  ]]; then
      exit 255;
    elif [[ $1 == *"error(s)"* ]]; then
      exit 255;
    fi
  fi

}

if [[ ! -v AWS_ACCESS_KEY_ID ] && [ ! -v AWS_SECRET_ACCESS_KEY ] && [ ! -v AWS_REGION ]]; then
    echo "DEPLOY_ENV is not set"
    exit 0
else
    echo "DEPLOY_ENVs are set"
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
    aws configure set region $AWS_REGION
fi

set EB_NAME=${1}
set fn=${2}
set EB_ENV=${3}

eb init -p python-3.6 "$EB_NAME" --region "$AWS_REGION"

# Clone existing beanstalk environment into BLUE environment
eb clone "$EB_ENV" --clone_name "$EB_ENV-blue" --cname "$EB_ENV-$ENV-blue"
checkSuccessCode $?

# Sleep to let the environment get started
sleep 60

# Status of Blue environment
eb status "$EB_ENV-blue"

# Swap urls of Green environment with new Blue environment
eb swap "$EB_ENV" --destination_name "$EB_ENV-blue"
checkSuccessCode $?

# Sleep to let the environments swap urls,keeping it 60 since default TTL is 60
sleep 60

# Set "$EB_ENV" as default environment
eb use "$EB_ENV"

# Status of environments
echo "Blue Enviromnet $EB_ENV-blue Status"
eb status "$EB_ENV-blue"

echo "Green Enviromnet $EB_ENV Status"
eb status "$EB_ENV"

#Output clone status , to be used in next stage to determine if we need to modify route 53 or not.
echo "isCloned=YES" > isCloned.txt

#Check if the application version already exists
existingAppVersion=`aws elasticbeanstalk describe-application-versions --application-name "$EB_NAME" --version-labels $fn --query 'ApplicationVersions[0].VersionLabel' --output text`
if [[ "$fn" == "$existingAppVersion" ]]; then
	echo "Application with version $existingAppVersion already exists, there will be no deployment..."
else
	echo "Application with version $existingAppVersion does not exists, creating application version..."
	# Create the beanstalk application
	aws elasticbeanstalk create-application-version --application-name "$EB_NAME" --version-label "$fn" --description "$fn" --source-bundle S3Bucket="$AWS_CENTRAL_REPOSITORY_BUCKET",S3Key="$s3_key"
	checkSuccessCode $?

	# Sleep to let the application create
	sleep 30

	# Create the Environment and use the timestamp as the label
	aws elasticbeanstalk update-environment --application-name "$EB_NAME" --environment-name "$EB_ENV" --version-label "$fn"
	checkSuccessCode $?
	
	# Sleep to let the environment get started
	sleep 30
fi

# Describe the new Environment; this will be used to get the Endpoint URL
describe_environment_output=`aws elasticbeanstalk describe-environments --environment-names $EB_ENV`


# Init elb with default region
eb init -p python-3.6 "$EB_NAME" --region "$AWS_REGION" --platform "Python"
checkSuccessCode $?

# Swap urls of Green environment with new Blue environment
eb swap "$EB_ENV" --destination_name "$EB_ENV-blue"
checkSuccessCode $?

# Sleep to let the environments swap urls
sleep 60s

eb scale '1' "$EB_ENV-blue"


# Init elb with default region
eb init -p python-3.6 "$EB_NAME" --region "$AWS_REGION" --platform "Python"

#Terminate the Blue environment without prompting for confirmation
eb terminate "$EB_ENV-blue" --force
checkSuccessCode $?