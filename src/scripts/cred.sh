#!/bin/bash

# Get temporary access keys from EC2 role
COMMAND="curl http://169.254.169.254/latest/meta-data/iam/security-credentials/"
ROLE=$($COMMAND)
AWS_ACCESS=$($COMMAND/$ROLE/ | jq ."AccessKeyId" | sed 's/"//g')
AWS_SECRET=$($COMMAND/$ROLE/ | jq ."SecretAccessKey" | sed 's/"//g')

# create and update the .boto file needed by bees
cd ~/
echo "[Credentials]" > .boto
echo "aws_access_key_id = $AWS_ACCESS" >> .boto
echo "aws_secret_access_key = $AWS_SECRET" >> .boto
chmod 600 .boto