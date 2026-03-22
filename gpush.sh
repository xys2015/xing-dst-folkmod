#!/bin/bash

# email=$(hostname)@localhost.com
# username=$(hostname)

email=xys721@163.com
username=kyle_mac

git config user.email $email
git config user.name  $username

git pull

git add .

if [ -z $1 ]; then
    git commit -m "$RANDOM" 
else
    git commit -m "$1"
fi

git push
# git push origin master

# git config core.quotepath false

