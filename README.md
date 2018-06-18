# AzCli 2.0 scripts collection
A short and unsorted collection of AzCli 2.0 scripts.
Covered topics:
- start all VMs in a subscription
- stop/deallocate all VMs in a subscription
- encrypt a VM (creates the Resource Group, KeyVault, key, secret, VM and then encrypts it)
- install OMS Agent extension on all VMs in subscription (this can be modified to install any Extension)
- install OMS Agent extension on all VMs in a Resource Group - modified version of the above
- install OMS on specific (defined in an array) VMs - again, modified version of the above


# Documentation:
* Azure CLI:

https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli?view=azure-cli-latest

https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli?view=azure-cli-latest#learn-cli-basics-with-quickstarts-and-tutorials

* Extensions:

https://docs.microsoft.com/en-us/cli/azure/vm/extension?view=azure-cli-latest

# Responsability disclaimer
The above scripts are provided "as it is".

Although I work for Microsoft, the scripts here are put together by me based on the currently publicly available documetation on the MSDN website and are in no way and under any circumstances to be considered as "Microsoft provided".

I'm just another dude giving back to the community, keep that in mind!

I'm not to be considered responsible and the same applies for my employeer, if the scritps, during execution, will harm your VMs or your environment, infrastructure, etc, in Azure or any other cloud, or on-premises. 

This is solely your own responsability.

* USE IT ON YOUR OWN RISK!!
