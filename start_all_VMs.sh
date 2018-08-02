#!/usr/bin/env bash
# Title:  	Start all VMs in subscription ID
# Author: 	Marin Nedea
# Usage:  	Change the variables to your own. 
#		Make sure the script has executable permissions:
#		chmod +x start_all_VMs.sh
#		execute the script by typing:  ./start_all_VMs.sh
# Requires	AzCli 2.0 to run: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest


# Declare the variables
sID=<your subscription id here>

# Set subscriptionID:
az account set --subscription $sID

# List all resource groups
declare -a rgarray="$(az group list  --query '[].name' -o tsv)"

#check if array is empty
if [ -z "$rgarray" ]; then
    echo "No resource group in this subscription: $sID"
	exit
else
	for  i in ${rgarray[@]};  do
	rgName=$i;
	
	# List all VMs for RG $rgName
	declare -a vmarray="$(az vm list -g $rgName --query '[].name' -o tsv)"

	#check if array is empty
	if [ -z "$vmarray" ]; then
			echo "No VM in $rgName" 				
	else
							
		for j in ${vmarray[@]}; do
		vmName=$j;		
		
		# Check if vm is running
		vm_state="$(az vm show -g $rgName -n $vmName -d --query powerState -o tsv)"
		
		if [[ "$vm_state" != "VM running" ]] ; then
			echo "Starting VM: $vmName "
			az vm start -g $rgName -n $vmName
		else
			echo "VM $vmName is already in running state."	
		fi
		
		done
	fi
	done  
fi

