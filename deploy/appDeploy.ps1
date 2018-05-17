Param(
	[Parameter(Mandatory=$true)][string] $Website,
	[string] $ResourceGroupName = "vanillawebapp-local-rg",
	[string] $ZipPackage = "$PSScriptRoot\app.zip"
)

$ErrorActionPreference = "Stop"

<#
.SYNOPSIS
This command deploys zip package to Azure RM Web App.
	
.DESCRIPTION
This command deploys zip package to Azure RM Web App.
	
.PARAMETER Website
	Web application name. E.g. <name>.azurewebsites.net.
.PARAMETER Password
	Password from publishing profile (from "userPWD" attribute).
.PARAMETER ZipPackage
	Full path to zip package to deploy. Note: Has to have "flat structure" (not Web Deploy Package structure).

.NOTES
This script is based on https://github.com/projectkudu/kudu/wiki/REST-API
Also good to know these topics:
https://github.com/projectkudu/kudu/wiki/Deploying-from-a-zip-file
https://github.com/projectkudu/kudu/wiki/Deployment-credentials

.LINK
https://github.com/projectkudu/kudu/wiki/REST-API

#>
function ZipDeploy([string] $Website, [string] $Password, [string] $ZipPackage)
{
	$username = "`$$Website"
	$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $Password)))
	$userAgent = "powershell/1.0"

	$apiUrl = "https://$Website.scm.azurewebsites.net/api/zip/site/wwwroot/"

	Write-Host "Deploying using Kudu Rest API $Website"
	$result = Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method PUT -InFile $ZipPackage -ContentType "multipart/form-data"
	$result
}

$publishProfileString = Get-AzureRmWebAppPublishingProfile `
	-Name $Website `
	-ResourceGroupName $ResourceGroupName `
	-OutputFile deploy.publishProfile `
	-Format WebDeploy

$publishProfile = [xml] $publishProfileString

$username = $publishProfile.publishData.publishProfile[0].userName
$password = $publishProfile.publishData.publishProfile[0].userPWD

Write-Host "Deploying using username $username"
ZipDeploy -Website $Website -Password $password -ZipPackage $ZipPackage
