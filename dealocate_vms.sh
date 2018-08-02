 #! /usr/bin/env bash

#########################################################################################################
# Title:  	Deallocate all VMs in subscription except a specific one				#
# Author: 	Marin Nedea										#
# Created: 	March 19th, 2018									#
# Usage:  	Change the variables to your own. 							#
#		Make sure the script has executable permissions:					#
#		chmod +x deallocate_vms.sh and execute the script by typing:  ./deallocate_vms.sh	#					#
# Requires:	AzCli 2.0 installed on the machine you're running this script on			#
# 		https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest	#
# 		If enabled, you can run it through the bash Cloud Shell in your Azure Portal page.	#
#########################################################################################################

# Exclude VM
vmexcept=<vm name to exclude from script>
sID="<your subscription id here>"

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

	# List all VMs for each resource group rgName
	declare -a vmarray="$(az vm list -g $rgName --query '[].name' -o tsv)"

	#check if array is empty
	if [ -z "$vmarray" ]; then
			echo "No VM in "$rgName 
	else
		for j in ${vmarray[@]}; do
		vmName=$j;
		
		#Check if VM is excluded
		if [[ "$vmName" == "$vmexcept" ]]; then
			echo "VM $vmName is excepted and will not be deallocated" 
		else
			# Check if Vm is not already stopped/deallocated
			vm_state="$(az vm show -g $rgName -n $vmName -d --query powerState -o tsv)"
			if [[ "$vm_state" != "VM deallocated" ]] ; then
				echo "Stopping/deallocating VM: $vmName "
				az vm deallocate -g $rgName -n $vmName
			else
				echo "VM $vmName is already in deallocated state."	
			fi
		fi
		done;  
	fi
    done; 
fi
