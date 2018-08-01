#!/usr/bin/env bash
#  Encrypt an existing VM with a KEK into a different RG
# Working version.

#############################
# Optional
# Login into Azure 
#az login

# If multiple subscription, set the one where VM and KeyVault are.
#az account set -s "<YourSubscriptionID>"
# END Optional
#############################

# Define VM variables
rgname="resource_group_name"
VMName="vm_name_here"
loc="azure_region_here"
vm_user="your_username"

# Define the name of the KeyVault and its Resource Group name that will be created.
keyvault_name="key vault name"
KVRG="key vault resource group name"

# Define the name of the Service Principal that will be created.
SPName="SP name"

# Define the name of the KEK
KVKeyName="Key name"

# Create VM RG
#az group create --name $rgname --location $loc

# Create the VM
#az vm create -g $rgname -n $VMName --image rhel --admin-username $vm_user --generate-ssh-keys

# If not already done, registre KV provider and then check if already existing
az provider register -n Microsoft.KeyVault
az provider show -n Microsoft.KeyVault

# Create KVault RG
# az group create --name $KVRG --location $loc

# Create KeyVault and Key
# az keyvault create --name $keyvault_name --resource-group $KVRG --location $loc --enabled-for-disk-encryption True
#az keyvault key create --vault-name $keyvault_name --name $KVKeyName --protection software
KEKUri="$(az keyvault key show --vault-name $keyvault_name --name $KVKeyName --query [key.kid] -o tsv)"
KEKV="$(az keyvault show -g $KVRG -n $keyvault_name --query [id] -o tsv)"

# Create SP with default permissions (NOTE DOWN and save the $pw for future use. Password is only shown during SP creation)
# Build an array containing the aadClient and aadPassword
declare -a appAndPw="$(az ad sp create-for-rbac -n $SPName --query [appId,password] -o tsv)"
# Define the array content as a variable with 2 values
appandpass="${appAndPw[*]}"
# Extract the values in the variable
aadClientID="$( echo $appandpass | awk '{print $1}')"
pw="$( echo $appandpass | awk '{print $2}')"

# Grant AAD Application the rights to use the KeyVault for ADE purpose
# az keyvault set-policy --name $keyvault_name --spn $aadClientID --key-permissions wrapKey --secret-permissions set

# Now, enable the encryption - This enable for "All" the disks
az vm encryption enable --resource-group $rgname --name $VMName --aad-client-id $aadClientID --aad-client-secret $pw --key-encryption-keyvault $KEKV --key-encryption-key $KEKUri --disk-encryption-keyvault $KEKV --volume-type ALL
