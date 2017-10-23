# ibera-supply-chain
Umbrella repository for iBera's blockchain based supply-chain solution.

* [Ethereum smart contract](https://github.com/CatalystCode/ibera-smart-contracts)
* [Core services](https://github.com/CatalystCode/ibera-services
)
* [Office 365 outlook integration](https://github.com/CatalystCode/ibera-office-integration)
* [Office 365 exchange document services](https://github.com/CatalystCode/ibera-document-service)

## Cloning the repo
```
git clone
git submodule init 
git submodule update --init --remote
git submodule foreach git checkout master
```

## Overview
coming soon ...
## Getting started locally
* [Build and deploy the smart contract to the block chain](https://github.com/CatalystCode/ibera-smart-contracts/blob/master/README.md) - for local development you either use `testrpc` or a local `geth` instance.
* [Configure and run the document service](https://github.com/CatalystCode/ibera-document-service) 
* [Configure and run the core service](https://github.com/CatalystCode/ibera-services) - update the configuration as described in the README and run the service using `npm start`
* [Configure and run the office integration service](https://github.com/CatalystCode/ibera-office-integration) - Follow the instructions in on `configuration` and `running in localhost`

## Deploying the solution to Azure
To deploy the solution, simply push the button

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)

The following resources will be created:
* Microsoft.ApiManagement
* Microsoft.Compute
* Microsoft.Network
* Microsoft.Storage
* Website






