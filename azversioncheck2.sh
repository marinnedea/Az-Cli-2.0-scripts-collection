#!/bin/bash

#########################################################################################################
# Title:  	Find Windows Azure Agent version on all VMs in all subscriptions 	                #
# Author: 	Marin Nedea										#
# Created: 	June 24th, 2020								       		#
# Usage:  	Just run the script with sh (e.g. sh script.sh) 	                 		#
# Requires:	AzCli 2.0 installed on the machine you're running this script on			#
# 		https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest	#
# 		If enabled, you can run it through the bash Cloud Shell in your Azure Portal page.	#
#########################################################################################################

echo "DISCLAIMER: 
This script is provided as it is, and without any warranty. Neither the authot or the company the author 
of this script works for at this moment, or will work in the future, shall be held responsible about any
harm the incorrect usage of this script may cause."
echo ""
echo ""
read -p "Are you sure you wish to continue? " -n 1 -r
echo ""
echo ""
if [[ $REPLY =~ ^[Yy]$ ]] ; then
 
echo "Script starting"  
# CSV file:
csv_file=/tmp/azagentversion.csv
backup_file=tmp/azagentversion.$(date +"%m-%d-%Y_%T" ).BKP.csv
csv_header="Subscription;ResourceGroup;VM Name;VM Power Status;OS type;Agent version"

# Create the csv file if does not exists; backup and create if already exist.
if [ ! -f $csv_file ]
then
    touch $csv_file && echo "Created $csv_file" 
	echo ""
	echo ""
else 
	mv  $csv_file $backup_file && echo "Created a backup of $csv_file as $backup_file" 
	echo ""
	echo ""
	touch $csv_file && echo "Created a new $csv_file"
	echo ""
	echo ""
fi
echo $csv_header > $csv_file

# Checking if there any account logged in azcli
if az account show > /dev/null 2>&1; then
	echo "You are already logged in."
else
	echo "Please login to Az CLI"
	az login
	echo ""
	echo ""
fi

	echo "Starting processing the data"
	echo ""
	echo ""

# Find all subscriptions:
for subs in $(az account list -o tsv | awk '{print $3}'); do

	# Find current logged in username 
	username=$(az account show --query user.name --output tsv)
	
	# Select subsctiption 1 by 1
	az account set --subscription $subs	
	
	echo "Cheching subscription $subs :"
	
	# Check running account read permissions over the selected subscription and send output to /dev/null to avoid screen clogging with unnecessary data.
	# Info: https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-cli#list-role-assignments-for-a-user
	# If user has permissions, the script will continue, else will skip this subscription and show a message on the screen.
	if az role assignment list --all --assignee $username --query [].roleDefinitionName  > /dev/null 2>&1; then 
	
		# List all resource groups in selected subscription
		declare -a rgarray="$(az group list  --query '[].name' -o tsv)"
		
		#check if array is empty
		if [ ! -z "$rgarray" ]; then

			for  rg in ${rgarray[@]}; do
			rgName=$rg;
			
			echo "- Checking Resource Group: $rgName"	
			
			# List all VMs for RG $rgName
			declare -a vmarray="$(az vm list -g $rgName --query '[].name' -o tsv)"
			
			# check if VM array is empty
			if [ ! -z "$vmarray" ]; then
											
				for vm in ${vmarray[@]}; do					
					vmName=$vm;						
					echo "-- Checking vm: $vmName" 
					
					osversion="$(az vm get-instance-view -g $rgName -n $vmName | grep -i osType| awk -F '"' '{printf $4 "\n"}')"
					echo "--- OS: $osversion"
					
					vmState="$(az vm show -g $rgName -n $vmName -d --query powerState -o tsv)"
					echo "--- VM Power state: $vmState"
					
					agentversion=$(az vm get-instance-view --resource-group $rgName --name $vmName | grep -i vmagentversion | awk -F"\"" '{print $4}')						
					# if Agent version does not return a value, set the value to "Unknown" 
					[ -z $agentversion ] && agentversion="Unknown" 
					echo "--- Windows Agent version: $agentversion"
					
					# Addding the necessary info to the CSV file. 
					echo "$subs;$rgName;$vmName;$vmState;$osversion;$agentversion" >> $csv_file
					echo ""
					echo ""
				done
			else
				echo "-- Found no VMs in this Resource Group"
				echo ""
				echo ""	
			fi
			done
		else 
		 echo "-- Found no Resource Group in this Subscription"
		 echo ""
		 echo ""	
		fi
	else
		echo "- You do not have the necessary permissions on subscription $subs.
		More information is available on https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-cli#list-role-assignments-for-a-user"
		echo ""
		echo ""		
	fi
	done
	
	echo "
	
	###########################################################################################################################
	
	
	Completed checking the Agent version on all subscriptions for all VMs.
	
	The results are saved in the CSV file $csv_file.
	
	To import the results in excel, please download the CSV file $csv_file from this VM and follow instructions on: 
	https://support.microsoft.com/en-us/office/import-or-export-text-txt-or-csv-files-5250ac4c-663c-47ce-937b-339e391393ba
	
	
	###########################################################################################################################

	"
	
	exit 0
else
	echo ""
	echo "Elvis has left the building! Aborting script!"
	echo ""
	exit 1
fi
