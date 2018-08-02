#! /usr/bin/env bash

########################################################################################################
# Title:        Remove OMS from all VMs in a specific subscription ID					#
# Author:       Marin Nedea										#
# Created:	March 19th, 2018									#
# Requirements: AzCli 2.0 must be already installed and running (logged in).				#
#		bash (not sh). sh doesn't understand arrays, so you'll have to run this in bash		#
#		There is a slight possibility you will need dos2unix utility also. See below.		#
# Usage:        Make sure the script has executable permissions:					#
#               chmod +x delete_OMS_all_VMs_in_subscription_id.sh 					#
#               Execute the script by typing:  ./delete_OMS_all_VMs_in_subscription_id.sh		#
#		Sometimes git will break the "unix" format of the file.					#
#		To restore it, just run dos2unix delete_OMS_all_VMs_in_subscription_id.sh		#
# NOTE:		You can remove all the echo's if you feel the script is too large. Your choice!		#
# Requires:	AzCli 2.0 installed on the machine you're running this script on			#
# 		https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest	#
# 		If enabled, you can run it through the bash Cloud Shell in your Azure Portal page.	#
########################################################################################################

# Create an array with the available subscriptions IDs
declare -a sidarray="$(az account list  --query '[].id' -o tsv)"

#check if array is empty
if [ -z "$sidarray" ]; then
    echo "You don't have access to any subscription. Please contact your Azure Account Owner!"
    exit 0
else
	# List available subscriptions:
	echo "" # Just adding a line
	echo "Subscriptions you have access to:"
	az account list -o table
fi

# Set one of the available subscription ID:
echo "Type the subscription ID that you want to use, followed by [ENTER]:"
read sID

# Check if supplied argument is empty
if [ -z "$sID" ] ; then
	echo "No subscriptionID supplied! Exiting!"
	exit 0
fi

# Check if the subscription ID supplied is part of the available subscriptions ID for you
if [[ ! ${sidarray[*]} =~ $sID ]]; then
	echo "" # Just adding a line
        echo "The subscription ID you typed is not a valid one, please run the script again and make sure you use the correct value."
else
	# Set subscriptionID:
	az account set --subscription $sID
   
	activesid="$(az account show | grep id | awk -F '"' '{printf $4 "\n"}')"
	if [[ $sID == $activesid ]] ; then
		echo "" # Just adding a line
		echo "Subscription set to: $sID."		 
	else
		echo "" # Just adding a line
		echo "Active subscription is $activesid, which is diferrent from $sID. Something went wrong with the script! Exiting!"
		exit 0		
	fi
fi

# List all resource groups
declare -a rgarray="$(az group list  --query '[].name' -o tsv)"

#check if array is empty
if [ -z "$rgarray" ]; then
	echo "" # Just adding a line
    	echo "No resource group in this subscription: $sID."
	exit 0
else
	for  i in ${rgarray[@]};  do
	rgName=$i;
	
	# List all VMs for RG $rgName in an array
	declare -a vmarray="$(az vm list -g $rgName --query '[].name' -o tsv)"

	#check if array is empty
	if [ -z "$vmarray" ]; then
		echo "" # Just adding a line
		echo "No VM in $rgName Resource Group." 		
	else
		echo "" # Just adding a line
		echo "VMs in $rgName Resource Group:"
		printf '%s\n' "${vmarray[@]}"
		
		for j in ${vmarray[@]}; do
		vmName=$j;	
		
		# Get the Operating System
		vm_os="$(az vm get-instance-view -g $rgName -n $vmName | grep -i osType| awk -F '"' '{printf $4 "\n"}')"
		
		if [[ "$vm_os" == "Linux" ]] ; then			
			extName=OmsAgentForLinux		
		else			
			extName=MicrosoftMonitoringAgent		
		fi
		
		# Create an array of installed extensions in the VM
		declare -a installedExt="$(az vm extension list  -g $rgName --vm-name $vmName --query "[].name" -o tsv)"
		echo "" # Just adding a line
		echo "Extensions installed on the $vmName:"
		printf '%s\n' "${installedExt[@]}"
		
		# Check if OMS is among the installed extensions
		if [[ ${installedExt[*]} =~ $extName ]]; then
			
			echo "" # Just adding a line
			echo "OMS is currently installed on the VM $vmName. Removing it!"
			# Make sure the VM running
			vm_state="$(az vm show -g $rgName -n $vmName -d --query powerState -o tsv)"

			if [[ "$vm_state" != "VM running" ]] ; then
				echo "Starting VM: $vmName."
				az vm start -g $rgName -n $vmName
				# Set a value to remeber the VM was powered OFF and to shut it back down at the end of script
				vmpowerstate=1
				echo "VM $vmName is now running. Continuing with the removal of $extName extension."
			else
				echo "VM $vmName is already in running state. No need to start it. Will continue with uninstalling the $extName extension."	
				vmpowerstate=0
			fi
				
			# Unisntall OMS agent on each VM $vmName
			az vm extension delete \
				--resource-group $rgName \
				--vm-name $vmName \
				--name $extName \
				
			echo "$extName is now removed from VM $vmName in RG $rgName."
			
			if [[ "$vmpowerstate" == 1 ]] ; then		
				echo "The VM $vmName was powered OFF and Deallocated before un-installing the extension. Deallocating the VM $vmName."
				az vm deallocate -g $rgName -n $vmName
				echo "The VM $vmName is now in deallocated status." 
			fi
			
		else
			echo "The extension $extName is not installed on the VM $vmName."
		fi 
		done
	fi
	done  
fi
