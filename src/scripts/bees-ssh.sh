#!/bin/sh

# Generate a key pair for access to active bees from beehives
cd ~/.ssh
ssh-keygen -t rsa -N "" -f bees
mv bees bees.pem
chmod 400 bees.pub
aws ec2 delete-key-pair --key-name "bees" --region us-east-1
aws ec2 import-key-pair --key-name "bees" --public-key-material file://~/.ssh/bees.pub --region us-east-1
