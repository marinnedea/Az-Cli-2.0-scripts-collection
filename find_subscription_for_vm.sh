#! /usr/bin/env bash

#replace myVm with your actual VM name
read -p 'Type the Vm name to search: ' findvmname

# List all subscriptions you have access and are enabled
declare -a accarray="$(az account list --all --query "[].id" -o tsv)"

#check if array is empty
if [ -z "$accarray" ]; then
    echo "No subscription enabled on this Azure account"
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
					echo "VM $vmName is in Subscription "$subid 
					exit 0
				else		
					echo "VM $vmName NOT found in Subscription "$subid	
				fi	
			fi
	done; 	
fi
