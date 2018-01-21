# Azure Deployment script
PowerShell script for deploying ARM templates to create the Supply Chain solution in Azure.

## Pre Requisites
To run the deployment script, please make sure you have the following pre-requisites:
1.	PowerShell to run the script
2.	Node v8.4 or later
3.	Azure subscription

## Getting Started
Before running the script open the `deploy.conf` file and set the script configuration values.
Here is a brief description of the configuration values:

### [General]
* `deploymentType`: This is the deployment type. It can be one of two types:
    1.	WebApp: This is an environment for development and preview purposes. It is less secured and should not be used for production purposes.
    2.	ASE: Use this option to deploy a secured environment with App Service Environment. Note: this option costs more than the WebApp option, but is recommended for production purposes.
* `namePrefix`: The name prefix of all the resources created by this script, except the Network Interfaces and the Storage Accounts of the Ethereum Consortium resources.
* `resourceGroupName`: The Resource Group name that will include all the created resources by this script.
* `resourceGroupLocation`: The geographic location of the resource group. Please choose one of the locations listed [here](https://azure.microsoft.com/en-us/regions/)
* `deploymentName`: The name of the deployment.
* `gitSmartContractsRepoURL`: The Smart Contracts repository git URL. Default value: `https://raw.githubusercontent.com/Azure/supply-chain-smart-contracts`
* `gitSmartContractsFolder`: The folder name where the smart contracts repository will be cloned. Default value: `supply-chain-smart-contracts`
* `mainRepositoryLocation`: The location URL where is the resources of the main repository (the Supply Chain umbrella) are available for download. Default value: `https://raw.githubusercontent.com/Azure/blockchain-supply-chain-sloution/`
* `mainRepositoryBranch`: The used branch of the main repository. Default value: `master`

### [Ethereum Consortium]
* `adminUsername`: The user name used to access the VMs produced by this script. Default value: `auser1`
* `adminPassword`: The password used to access the VMs produced by this script. Default value: `AUser1234567`
* `ethereumAccountPsswd`: The password to access the Ethereum account. Default value: `AUser1234567`
* `ethereumAccountPassphrase`: The pass phase of the Ethereum account. Default value: `AUser1234567`
* `ethereumNetworkID`: The Ethereum Network ID. Default value: `1010101`
* `numConsortiumMembers`: The number of the members in the Ethereum Consortium. Default value: `2`
* `numMiningNodesPerMember`: The number of the mining nodes for each member. Default value: `1`
* `mnNodeVMSize`: The VM size of the mining nodes. Please choose one from [this list](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general). Default value: `Standard_D2_v2`
* `numTXNodes`: The number of the transactions nodes. Default value: `1`
* `txNodeVMSize`: The VM size of the transactions nodes. Please choose one from [this list](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general). Default value: `Standard_D2_v2`

### [Supply Chain]
* `servicesName`: The name of the Services web app. Default value: `servicesapi`
* `oiName`: The name of the Office Integration web app. Default value: `oiapi`
* `servicesStorageAccountName`: The name of the storage account used by the Services web app. Default value: `svcstorage`
* `oiStorageAccountName`: The name of the storage account used by the Office Integration web app. Default value: `oistorage`
* `gitServicesRepoURL`: The Services repository git URL. Default value: `https://github.com/Azure/supply-chain-services.git`
* `gitServicesBranch`: The used branch of the Services repository. Default value: `master`
* `gitOiRepoURL`: The Office Integration repository git URL. Default value: `https://github.com/Azure/supply-chain-office-integration.git`
* `gitOiBranch`: The used branch of the Office Integration repository. Default value: `master`

## Running the script
To deploy the solution in Azure, make sure you have the pre-requisites listed in the beginning of this document, and make sure you set the required deployment parameters in the `deploy.conf` file, and then follow these steps:
1.	Open PowerShell.

2.	Login to Azure using the following command in the PowerShell command line:
    ```
    > Login-AzureRmAccount
    ```
    This will open the azure login page in you default web browser. Please enter your credentials and login.

3.	After logging in, the default subscription will be used. If you have more than one subscription, and wish to use another subscription, use the following command in the PowerShell command line:
    ```
    > Select-AzureRmSubscription -SubscriptionId <your subscription id>
    ```

4.	Change directory (cd) to the azure-deployment directory (to this directory where the deployScript.ps1 exists).

5.	Run the deployScript.ps1 script with this command:
    ```
    > .\deployScript.ps1
    ```
    The deployment starts, and it will take between 1-2 hours to complete, mainly according to the provided deployment type (ASE takes more time), and according to the provided configurations of the Ethereum Consortium.

After the deployment completed, login to your Azure account, and search for the Resource Group name you provided. You’ll find the resources under it.

[Go back](https://github.com/Azure/blockchain-supply-chain-sloution) to the main repository.
