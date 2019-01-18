#! /usr/bin/env bash

# The script will run only under bash, as it is using arrays!! 
# sh/zsh doesn't understand the "declare" function.
# To run the script, use the following command:
# chmod +x find_subscription_for_vm.sh && ./find_subscription_for_vm.sh
# Enjoy!

#Type the Vm name when prompted
read -p 'Type the Vm name to search: ' findvmname

# List all subscriptions you have access and are enabled
declare -a accarray="$(az account list --all --query "[].id" -o tsv)"

#check if array is empty
if [ -z "$accarray" ]; then
    echo "No subscription enabled on this account"
    exit 0
else
        for i in ${accarray[@]};  do

        subid=$i;

        # List all VMs in subscription $subid
        declare -a vmarray="$(az vm list --subscription $subid --query "[].name" -o tsv)"

        #check if array is empty
        if [ -z "$vmarray" ]; then
                echo "No VM in subscription "$subid
        else
                for j in ${vmarray[@]}; do
                        vmName=$j;

                        #Check if the VM name you search is present
                        if [[ "$vmName" == "$findvmname" ]]; then
                                echo "VM $findvmname is in Subscription "$subid
                                exit 0
                        fi
                done;
        fi
        done;
fi
