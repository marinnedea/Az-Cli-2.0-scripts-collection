#!/usr/bin/env bash
# Title:  	Oms Install on multiple predefined VMs in the same RG
# Author: 	Marin Nedea 
# Usage:  	Change the variables to your own. 
#			Make sure the script has executable permissions:
#			chmod +x oms_install_multiple_MVs.sh
#			Change myVM1 myVM2 myVM3  myVM5 myVM25 in the $vmarray with actual VM names.
#			execute the script by typing:  ./oms_install_multiple_MVs.sh
########################################################################################


# Declare the variables
omsid=<Workspace ID here>
omskey=<OMS key here>
extVersion=<OMS Version here, e.g 1.0>
sID=<your subscription id here>
rgName=<Your resource group here>

# Set subscriptionID:
az account set --subscription $sID 

# Add the VMs you want to have the extension installed into an array
declare -a vmarray=(myVM1 myVM2 myVM3  myVM5 myVM25)

# Make sure the VMs are running
for i in ${vmarray[@]}; do
vmName=$i;

	# Make sure the VM running
	vm_state="$(az vm show -g $rgName -n $vmName -d --query powerState -o tsv)"

	if [[ "$vm_state" != "VM running" ]] ; then
		echo "Starting VM: $vmName "
		az vm start -g $rgName -n $vmName
	else
		echo "VM $vmName is already in running state."	
	fi					
	
	# Get the Operating System
	vm_os="$(az vm get-instance-view -g $rgName -n $vmName | grep -i osType| awk -F '"' '{printf $4 "\n"}')"
	
	if [[ "$vm_os" == "Linux" ]] ; then			
		extName=OmsAgentForLinux		
		# Currently, the available versions are: 1.0, 1.2, 1.3, 1.4
		extVersion=1.4
	else			
		extName=MicrosoftMonitoringAgent		
		# Currently, the available versions are: 1.0
		extVersion=1.0
	fi
	
	# Create an array of installed extensions in the VM
	declare -a installedExt="$(az vm extension list  -g $rgName --vm-name $vmName --query "[].name" -o tsv)"
	
	if [[ ! " ${installedExt[@]} " =~ " $extName " ]]; then
	
	# Install the OMS extension on VM
	az vm extension set \
		--resource-group $rgName \
		--vm-name $vmName \
		--name $extName \
		--publisher Microsoft.EnterpriseCloud.Monitoring \
		--version $extVersion --protected-settings '{"workspaceKey": "'"$omskey"'"}' \
		--settings '{"workspaceId": "'"$omsid"'"}'  
	echo "$extName installed on VM $vmName in RG $rgName."
	else
		echo "The extension $extName is already installed on the VM $vmName"
	fi  

done
