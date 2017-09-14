
$confFileName = "deploy.conf";
$etheriumConsertiumTemplateFilePath = "etheriumConsertiumTemplate.json";
$etheriumConsertiumParametersFilePath = "etheriumConsertiumParameters.json";
$supplyChainTemplateFilePath = "supplyChainTemplate.json";
$supplyChainParametersFilePath = "supplyChainParameters.json";
$documentServicesEndPoint = 'https://ibera-document-service.azurewebsites.net';

#Read the configuration file
Get-Content $confFileName | foreach-object -begin {$conf=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $conf.Add($k[0], $k[1]) } }

$subscriptionId = $conf["subscriptionId"];
$resourceGroupName = $conf["resourceGroupName"];
$resourceGroupLocation = $conf["resourceGroupLocation"];
$namePrefix = $conf["namePrefix"];
$etheriumTxRpcPassword = $conf["ethereumAccountPsswd"];

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

# sign in
Write-Host "Logging in...";
Login-AzureRmAccount;

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;

# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.network","microsoft.storage","microsoft.web");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

#Update the Etherium Consertium parameters file:
$etheriumConsertiumParameters = Get-Content $etheriumConsertiumParametersFilePath -raw | ConvertFrom-Json;

$etheriumConsertiumParameters.parameters.namePrefix.value = $namePrefix;
$etheriumConsertiumParameters.parameters.adminUsername.value = $conf["adminUsername"];
$etheriumConsertiumParameters.parameters.adminPassword.value = $conf["adminPassword"];
$etheriumConsertiumParameters.parameters.ethereumAccountPsswd.value = $conf["ethereumAccountPsswd"];
$etheriumConsertiumParameters.parameters.ethereumAccountPassphrase.value = $conf["ethereumAccountPassphrase"];
$etheriumConsertiumParameters.parameters.ethereumNetworkID.value = [int]$conf["ethereumNetworkID"];
$etheriumConsertiumParameters.parameters.numConsortiumMembers.value = [int]$conf["numConsortiumMembers"];
$etheriumConsertiumParameters.parameters.numMiningNodesPerMember.value = [int]$conf["numMiningNodesPerMember"];
$etheriumConsertiumParameters.parameters.mnNodeVMSize.value = $conf["mnNodeVMSize"];
$etheriumConsertiumParameters.parameters.numTXNodes.value = [int]$conf["numTXNodes"];
$etheriumConsertiumParameters.parameters.txNodeVMSize.value = $conf["txNodeVMSize"];

$etheriumConsertiumParameters | ConvertTo-Json  | set-content $etheriumConsertiumParametersFilePath;


# Start the Etherium Consertium deployment
Write-Host "Starting Etherium deployment...";
$etheriumConsertiumOutput = New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $etheriumConsertiumTemplateFilePath -TemplateParameterFile $etheriumConsertiumParametersFilePath;

$ethRpcEndpoint = $etheriumConsertiumOutput.Outputs.'ethereum-rpc-endpoint'.value;
$ethVnetName = (Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName).name;

Write-Host "ethRpcEndpoint = '$ethRpcEndpoint'";
Write-Host "ethVnetName = '$ethVnetName'";

#Clone Smart Contracts repo and install it:
$supplyChainPath = pwd;
cd ..
git clone $conf["gitSmartContractsRepoURL"]
cd(Get-ChildItem -Directory . | sort CreationTime | select -l 1);
npm install

#Create public IP for the Etherium TX0 VM:
$pip = New-AzureRmPublicIpAddress -Name "tx0PublicIpAddress" -ResourceGroupName $resourceGroupName -AllocationMethod "Static" -Location $resourceGroupLocation;
$txNic = Get-AzureRmNetworkInterface -Name "nic-tx0" -ResourceGroupName $resourceGroupName;
$txNic.IpConfigurations[0].PublicIpAddress = $pip;
Set-AzureRmNetworkInterface -NetworkInterface $txNic;
Write-Host "Created a new public IP address to the Ethereum TX0 VM: $pip.IpAddress";
$ethRpcTx0Endpoint = "http://" + $pip.IpAddress + ":8545";

#Deploy the smart contract to the Etherium TX VM:
$deployCommand = "node deploy ProofOfProduceQuality $ethRpcTx0Endpoint $etheriumTxRpcPassword"
Write-Host "Deploying smart contracts using the following command: $deployResult";
$deployResult = Invoke-Expression "$deployCommand 2>&1" 
Write-Host $deployResult

#Removing the public IP for the Etherium TX0 VM:
#$txNic.IpConfigurations[0].PublicIpAddress = "";

#Get the deployment result and extract the Account and Contract addresses in case of success or the Error string in case of failure:
$deployResultJson = ('{'+($deployResult -split '{')[-1] | ConvertFrom-Json)
$deploymentError = $deployResultJson.error;
if($deploymentError){
	Write-Host 'deploymentError= ' $deploymentError;
}else{
	$accountAddress = $deployResultJson.accountAddress;
	$contractAddress = $deployResultJson.contractAddress;
	Write-Host 'accountAddress= ' $accountAddress;
	Write-Host 'contractAddress= ' $contractAddress;
}

#Return to the original Supplu Chain project directory
cd $supplyChainPath


$supplyChainParameters = Get-Content $supplyChainParametersFilePath -raw | ConvertFrom-Json;

$supplyChainParameters.parameters.deploymentPreFix.value = $namePrefix;
$supplyChainParameters.parameters.hostingEnvLocationName.value = $resourceGroupLocation;
$supplyChainParameters.parameters.servicesName.value = $conf["servicesName"];
$supplyChainParameters.parameters.oiName.value = $conf["oiName"];
$supplyChainParameters.parameters.servicesStorageAccountName.value = $conf["servicesStorageAccountName"];
$supplyChainParameters.parameters.gitServicesRepoURL.value = $conf["gitServicesRepoURL"];
$supplyChainParameters.parameters.gitServicesBranch.value = $conf["gitServicesBranch"];
$supplyChainParameters.parameters.gitOiRepoURL.value = $conf["gitOiRepoURL"];
$supplyChainParameters.parameters.gitOiBranch.value = $conf["gitOiBranch"];

$supplyChainParameters | ConvertTo-Json  | set-content $supplyChainParametersFilePath;

# Start the Supply Chain deployment
Try
{
	Write-Host "Starting Supply Chain deployment...";
	New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $supplyChainTemplateFilePath -TemplateParameterFile $supplyChainParametersFilePath;
}
Catch
{
	Write-Host $_.Exception.Message
}

#Getting Services webapp and Office Integration webapp endpoints:
$officeIntegrationWebappName = $namePrefix + $conf["oiName"];
$servicesWebappName = $namePrefix + $conf["servicesName"];
$servicesWebappEndpoint = 'https://'+(Get-AzureRmWebApp -Name $servicesWebappName -ResourceGroupName $resourceGroupName).DefaultHostName;
$oiWebappEndpoint = 'https://'+(Get-AzureRmWebApp -Name $officeIntegrationWebappName -ResourceGroupName $resourceGroupName).DefaultHostName;
Write-Host "servicesWebappEndpoint = '$servicesWebappEndpoint'";
Write-Host "oiWebappEndpoint = '$oiWebappEndpoint'";

#Getting storage account connection string:
$storageName = $namePrefix + $conf["servicesStorageAccountName"];
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageName).Value[0];
$storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=' + $storageName + ';AccountKey=' + $storageKey + ';EndpointSuffix=core.windows.net';
Write-Host "storageConnectionString = '$storageConnectionString'";

#Setting Services webapp environment variables:
$servicesWebapp = Get-AzureRMWebAppSlot -ResourceGroupName $resourceGroupName -Name $servicesWebappName -Slot production
$servicesWebappSettingList = $servicesWebapp.SiteConfig.AppSettings

$servicesWebappHash = @{}
ForEach ($kvp in $servicesWebappSettingList) {
    $servicesWebappHash[$kvp.Name] = $kvp.Value
}
$servicesWebappHash['CONTRACT_ADDRESS'] = $contractAddress;
$servicesWebappHash['ACCOUNT_ADDRESS'] = $accountAddress;
$servicesWebappHash['ACCOUNT_PASSWORD'] = $etheriumTxRpcPassword;
$servicesWebappHash['GAS'] = '2000';
$servicesWebappHash['GET_RPC_ENDPOINT'] = $ethRpcEndpoint;
$servicesWebappHash['AZURE_STORAGE_CONNECTION_STRING'] = $storageConnectionString;

Set-AzureRMWebAppSlot -ResourceGroupName $resourceGroupName -Name $servicesWebappName -AppSettings $servicesWebappHash -Slot production


#Setting OfficeIntegration webapp environment variables:
$oiWebapp = Get-AzureRMWebAppSlot -ResourceGroupName $resourceGroupName -Name $officeIntegrationWebappName -Slot production
$oiWebappSettingList = $oiWebapp.SiteConfig.AppSettings

$oiWebappHash = @{}
ForEach ($kvp in $oiWebappSettingList) {
    $oiWebappHash[$kvp.Name] = $kvp.Value
}
$oiWebappHash['IBERA_SERVICES_ENDPOINT'] = $servicesWebappEndpoint;
$oiWebappHash['DOCUMENT_SERVICES_ENDPOINT'] = $documentServicesEndPoint;
$oiWebappHash['OUTLOOK_SERVICE_ENDPOINT'] = $oiWebappEndpoint;

Set-AzureRMWebAppSlot -ResourceGroupName $resourceGroupName -Name $officeIntegrationWebappName -AppSettings $oiWebappHash -Slot production
