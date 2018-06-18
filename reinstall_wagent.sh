#! /usr/bin/env bash

yum remove WAlinuxAgent
cd /tmp
wget https://github.com/Azure/WALinuxAgent/archive/v2.2.3.zip 
unzip v2.2.3.zip
cd WALinuxAgent-2.2.3
python setup.py install 

exit 0
