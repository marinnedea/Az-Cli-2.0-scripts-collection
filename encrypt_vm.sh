#! /usr/bin/env bash
#################################################################################################
# Author:       Marin Nedea                                                                     #
# Created:      March 19th, 2018                                                                #
# Requirements: AzCli 2.0 must be already installed and running (logged in).                    #
#               bash (not sh). sh doesn't understand arrays, so you'll have to run this in bash #
#               There is a slight possibility you will need dos2unix utility also. See below.   #
# Usage:        Make sure the script has executable permissions:                                #
#               chmod +x encrypt_vm.sh                                                          #
#               Execute the script by typing:  ./encrypt_vm.sh                                  #
#               Sometimes git will break the "unix" format of the file.                         #
#               To restore it, just run dos2unix encrypt_vm.sh.                                 #
# NOTE:         You can remove all the echo's if you feel the script is too large. Your choice! #
#################################################################################################


echo "Set a name for the Keyvault, followed by [ENTER]:"
read keyvault_name

echo "Set a name for the Keyvault Key, followed by [ENTER]:"
read myKeyname

echo "Set a name for the Resource Group to create, followed by [ENTER]:" 
read myRG

echo "Set the region for the VM, followed by [ENTER]:"
read region

echo "Put a name to the new VM, followed by [ENTER]:"
read myVM

echo "Set a username for the VM, followed by [ENTER]:"
read vm_user

echo "We will strart creating the Resource Group $myRG, then we will create the KeyVaul $keyvault_name and the KeyVault Key $myKeyname. Finally, the VM $myVM will be created with the UbuntuLTS OS" 


# Register the Key Vault provider and create a resource group.
az provider register -n Microsoft.KeyVault
az group create --name $myRG --location $region

# Create a Key Vault for storing keys and enabled for disk encryption.
az keyvault create --name $keyvault_name --resource-group $myRG --location $region  --enabled-for-disk-encryption True

# Create a key within the Key Vault.
az keyvault key create --vault-name $keyvault_name --name $myKeyname --protection software

# Create an Azure Active Directory service principal for authenticating requests to Key Vault.
# Read in the service principal ID and password for use in later commands.
read sp_id sp_password <<< $(az ad sp create-for-rbac --query [appId,password] -o tsv)

# Grant permissions on the Key Vault to the AAD service principal.
az keyvault set-policy --name $keyvault_name --spn $sp_id --key-permissions backup create decrypt delete encrypt get import list purge recover restore sign unwrapKey update verify wrapKey --secret-permissions backup delete get list purge recover restore set

# Create a virtual machine.
az vm create --resource-group $myRG --name $myVM --image UbuntuLTS --admin-username $vm_user --generate-ssh-keys

# Encrypt the VM disks.
az vm encryption enable --resource-group $myRG --name $myVM --aad-client-id $sp_id --aad-client-secret $sp_password --disk-encryption-keyvault $keyvault_name --key-encryption-key $myKeyname --volume-type all

# Output how to monitor the encryption status and next steps.
echo "The encryption process can take some time. View status with:

    az vm encryption show --resource-group $myRG --name $myVM --query [osDisk] -o tsv

    When encryption status shows \`VMRestartPending\`, restart the VM with:

    az vm restart --resource-group $myRG --name $myVM"
