#!/usr/bin/env bash
#
# You have to be logged in to AzCli to run this.

# az login

# The script will iterate through all subscriptions, identify which VMs are 
# running Linux and have disks attached; if the VMs are deallocated, the script
# will check if the VM is generalized (prepared to become an image). If the VM  
# is not generalized, the script will start the VM, apply the fix than stop the
# VM back.
# For the VMs that were already powered ON, it will only apply the fix.


# To run this, just:
# chmod +x fixuuidfstab.sh && ./fixuuidfstab.sh

# Function to trigger the fix
function fix_uuids(){
        az vm extension set \
        --resource-group $vmRGName \
        --vm-name $vmName \
        --name customScript \
        --publisher Microsoft.Azure.Extensions \
        --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/marinnedea/scripts/master/uuidfstab.bash"],"commandToExecute": "chmod +x uuidfstab.bash && ./uuidfstab.bash /etc/fstab"}'

        echo "Updated fstab entries in VM: $vmName"
}

# List all your subscriptions
declare -a sidarray="$(az account list --query [].id -o tsv)"
if [ -z "$sidarray" ]; then
        echo "No subscriptions IDs available. Stopping here."
        exit 0
else
	#for each subscription
        for i in ${sidarray[@]};  do
                sID=$i;
                # Set subscriptionID:
                az account set -s $sID
                echo "Subscription: $sID set."
		
		# List all VMs in subscription
                declare -a vmsdetails="$(az vm list -d --query '[].{Name:name, OS:storageProfile.osDisk.osType, Power:powerState, RG:resourceGroup}' -o tsv)"

                printf '%s\n' "${vmsdetails[*]}" | while read line; do

                        vmName="$(echo $line | awk '{print $1}')"
                        vmOSType="$(echo $line | awk '{print $2}')"
                        vmpowerState="$(echo $line | awk '{print $4}')"
                        vmRGName="$(echo $line | awk '{print $5}')"

                        echo "Found VM $vmName in Resource Group $vmRGName."
                        echo "The VM is running $vmOSType."
                        echo "The Vm Power State is: $vmpowerState."

                        if [[ "$vmOSType" == "Linux" ]] ; then

                                declare -a datadisks="$(az vm show  -g $vmRGName -n $vmName --query storageProfile.dataDisks[*] -o tsv)"

                                #If datadisks array not empty
                                if [ ! -z "$datadisks" ]; then

                                        if [[ "$vmpowerState" != "running" ]] ; then

                                                echo "Finding out if VM $vmName is generalized."
                                                generalizedStat="$(az vm get-instance-view  -g $vmRGName -n $vmName --query 'instanceView.statuses[0].displayStatus' -o tsv)"

                                                if [[ "$generalizedStat" != "VM generalized" ]] ; then

                                                        echo "VM $vmName not generalized. Starting it up."
                                                        az vm start -g $vmRGName -n $vmName

                                                        echo "VM $vmName power state is: running. Applying fix."
                                                        #Calling the function to run the fix UUIDs script:
                                                        fix_uuids

                                                        echo "VM $vmName reverted back to deallocated status."
							az vm stop -g $vmRGName -n $vmName

                                                else

                                                        echo "$vmName is generalized. No operations possible on it. Skipping!"

                                                fi
                                        else
                                                echo "VM $vmName power state is: running. Applying fix."
                                                #Calling the function to run the fix UUIDs script:
                                                fix_uuids

                                        fi
                                else
                                        # datadisks array is empty
                                        echo "VM $vmName has no data disk attached. Skipping!"
                                fi
                        else
                                echo "VM $vmName is not running Linux. Skipping."
                        fi
                done
        done
fi
exit 0

