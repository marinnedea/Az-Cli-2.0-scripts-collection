#!/usr/bin/env bash
#
# You have to be logged in to run this.

# az login

# The script will iterate through all subscriptions, identify which VMs are 
# running Linux, if they are deallocated will start them, apply the script, 
# and set back the power status for the deallocated VMs.
# For the VMs that were already powered ON, it will only apply the script.

# To run this, just:
# chmod +x fixuuidfstab.sh && ./fixuuidfstab.sh


declare -a sidarray="$(az account list --o tsv | awk '{printf $2 "\n"}')"
if [ -z "$sidarray" ]; then
	echo "No subscriptions IDs available" 				
else
	for  h in ${sidarray[@]};  do
		sID=$h;
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
					
					# Make sure the VM running
					vm_state="$(az vm show -g $rgName -n $vmName -d --query powerState -o tsv)"

						if [[ "$vm_state" != "VM running" ]] ; then
							echo "Starting VM: $vmName "
							az vm start -g $rgName -n $vmName
						fi
								
						# Get the Operating System
						vm_os="$(az vm get-instance-view -g $rgName -n $vmName | grep -i osType| awk -F '"' '{printf $4 "\n"}')"
						
						if [[ "$vm_os" == "Linux" ]] ; then			
						#OS = Linux 					
						az vm extension set \
							  --resource-group $rgName \
							  --vm-name $vmName \
							  --name customScript \
							  --publisher Microsoft.Azure.Extensions \
							  --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/marinnedea/scripts/master/uuidfstab.bash"],"commandToExecute": "chmod +x uuidfstab.bash && ./uuidfstab.bash /etc/fstab"}'
						fi
						
						# Stop / Deallocating back the VMs that were in Deallocated state before applying the changes:
						if [[ "$vm_state" != "VM running" ]] ; then
							echo "Stopping back: $vmName "
							az vm stop -g $rgName -n $vmName
						fi
						
				done
			fi
		done  
	fi
done
fi
