# Lab - Connection Monitor with Bicep

This repo is a lab to **play with Connection Monitor**, part of Network Watcher.

It contains basically Azure Bicep code to provision following infrastructure:

![Big Picture](docs/architecture.png)

In addition to this hub & spoke, on-premise & S2S VPN, Bicep code will create Azure Network Watcher in the target subscription and configure a Connection Monitor that will:

* Monitor connectivity between **hubVM** and **spoke01 Azure VM** on SSH protocol every 30 seconds.
* Monitor connectivity between **hubVM** and **spoke02 Azure VM** on SSH protocol every 30 seconds.
* Monitor connectivity between **hubVM** and **onprem VM** (using its private IP address instead of Azure Resource Id) on SSH protocol every 30 seconds.
* Monitor connectivity between **spoke02VM Azure VM** and **public URL** [http://ident.me](http://ident.me) on HTTP protocol every 30 seconds. 

## Quick start

```bash
# Select subscription
az account set -s "....."
# Deploy infrastructure
az deployment sub create --template-file main.bicep --location centralindia

``` 

Enjoy & feel free to ping me & provide me feedbacks! 
