#!/usr/bin/env bash
for f in $(az account list -o tsv | awk '{print $3}')
do
	az account set --subscription $f
	# List all resource groups
declare -a rgarray="$(az group list  --query '[].name' -o tsv)"
#check if array is empty
if [ -z "$rgarray" ]; then
    echo "No resource group in this subscription: $f"
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
		
		# verify if the VM running
		vm_state="$(az vm show -g $rgName -n $vmName -d --query powerState -o tsv)"
		if [[ "$vm_state" != "VM running" ]] ; then
			echo "VM $vmName from RG $rgName in subscription $f is powered off/deallocated. Cannot verify VMAgent version."
		fi
				
		# Get the OS version. If Windows, skip.
		vm_os="$(az vm get-instance-view -g $rgName -n $vmName | grep -i osType| awk -F '"' '{printf $4 "\n"}')"
		
		if [[ "$vm_os" == "Linux" ]] ; then			
	  	
		# Get the vmAgent version of VM
		agentversion=$(az vm get-instance-view --resource-group $rgName --name $vmName | grep -i vmagentversion | awk '{print $2}')
		
		echo "$vmName;$agentversion"
		fi
		
		done
	fi
	done  
fi
done
