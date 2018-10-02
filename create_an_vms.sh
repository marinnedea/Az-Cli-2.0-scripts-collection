#!/usr/bin/env bash

# Creates 1 VM for each supported distribution and enables Accelerated Networking on it:
# https://docs.microsoft.com/en-us/azure/virtual-network/create-vm-accelerated-networking-cli#supported-operating-systems 
# Requires az cli v2.x

#############################
# Optional
# Login into Azure
#az login

# If multiple subscription, set the one where VM and KeyVault are.
#az account set -s "<YourSubscriptionID>"
# END Optional
#############################

# Decide on a region for the resources to be created
region="Set_Region_Here"

# Set a resource group name and create it
rgName="Set_Resource_Group_Here"
az group create --name $rgName --location $region

# Use a specific username
userName="azureuser"

# Set the VM size. Check you quota for a specific region before selecting the VM size, but also the suported VM size for AN.
# Take into consideration this script will create 8 VMs, each the same size. 
# If you set a VM size that will create, let's say. 8vCPUs VMs, you'll use 84 vCPUs from your quota in the selected region.
vmsize="Standard_DS4_v2"

# Set the network parametters:
ANVnet="myANVnet"
ANSubnet="myANSubnet"
ANNSG="myANNSG"
nsgruleName="Allow-SSH-Internet"

# Create a virtual network with az network vnet create. The following example creates a virtual network named myVnet with one subnet
az network vnet create -g $rgName --name $ANVnet --address-prefix 192.168.0.0/16 --subnet-name $ANSubnet --subnet-prefix 192.168.1.0/24

# Create a network security group
az network nsg create -g $rgName --name $ANNSG

# Open a port to allow SSH access to the virtual machine with az network nsg rule create:
az network nsg rule create -g $rgName --nsg-name $ANNSG --name $nsgruleName --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*"  --destination-address-prefix "*" --destination-port-range 22

# Simulate a multidimensional array for the VMs we need to create, each subarray containing the VM name and Linux Image URN/SKU
declare -a vms

vms[0]='UbuntuAN1;Canonical:UbuntuServer:16.04.0-LTS:16.04.201808140;1'
vms[1]='SLESAN1;SUSE:SLES:12-SP3:2018.09.04;2'
vms[2]='RHELAN1;RedHat:RHEL:7.4:7.4.2018010506;3'
vms[3]='CentOSAN1;OpenLogic:CentOS:7.4:7.4.20180704;4'
vms[4]='CoreOSAN1;CoreOS:CoreOS:Stable:1855.4.0;5'
vms[5]='DebianAN1;credativ:Debian:9:9.0.201808270;6'
vms[6]='OracleUEKAN1;Oracle:Oracle-Linux:7.4:7.4.20180424;7'
vms[7]='OracleRHCKAN1;Oracle:Oracle-Linux:7.4:7.4.20180424;8'

# I used the same image for Oracle.
# Will switch the boot order after creating them in order to get one booting the RHCK kernel.

for i in "${vms[@]}"
do
        arr=(${i//;/ })
        vmName=${arr[0]}
        vmImage=${arr[1]}
        c=${arr[2]}

# Create a public IP address with az network public-ip create.
# A public IP address isn't required if you don't plan to access the virtual machine from the Internet, so you may skip this step.
az network public-ip create --name ANPubIp$c -g $rgName

# Create a network interface with az network nic create with accelerated networking enabled.
az network nic create  -g $rgName --name ANNic$c --vnet-name $ANVnet --subnet $ANSubnet --accelerated-networking true --public-ip-address ANPubIp$c --network-security-group $ANNSG

# Create the VM and attach the NIC you just created to the VM:
az vm create -g $rgName -n $vmName --image $vmImage --size $vmsize --admin-username $userName --generate-ssh-keys --nics ANNic$c

done
