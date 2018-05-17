Param (
	[string] $ResourceGroupName = "vanillawebapp-local-rg",
	[string] $Location = "North Europe",
	[string] $Template = "$PSScriptRoot\azuredeploy.json",
	[string] $TemplateParameters = "$PSScriptRoot\azuredeploy.parameters.json",
	[string] $AppServicePricingTier = "B1",
	[string] $AppServiceInstances = 1
)

$ErrorActionPreference = "Stop"

$date = (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss")
$deploymentName = "Local-$date"

if ([string]::IsNullOrEmpty($env:RELEASE_DEFINITIONNAME))
{
	Write-Host (@"
Not executing inside VSTS Release Management.
Make sure you have done "Login-AzureRmAccount" and
"Select-AzureRmSubscription -SubscriptionName name"
so that script continues to work correctly for you.
"@)
}
else
{
	$deploymentName = $env:RELEASE_RELEASENAME
}

if ((Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue) -eq $null)
{
	Write-Warning "Resource group '$ResourceGroupName' doesn't exist and it will be created."
	New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
}

# Create additional parameters that we pass to the template deployment
$additionalParameters = New-Object -TypeName hashtable
$additionalParameters['appServicePlanSkuName'] = $AppServicePricingTier
$additionalParameters['appServicePlanInstances'] = $AppServiceInstances

$result = New-AzureRmResourceGroupDeployment `
	-DeploymentName $deploymentName `
	-ResourceGroupName $ResourceGroupName `
	-TemplateFile $Template `
	-TemplateParameterFile $TemplateParameters `
	@additionalParameters `
	-Verbose

$result

if ($result.Outputs -eq $null -or
	$result.Outputs.webAppName -eq $null -or
	$result.Outputs.webAppUri -eq $null)
{
	Throw "Template deployment didn't return web app information correctly and therefore deployment is cancelled."
}

$webAppName = $result.Outputs.webAppName.value
$webAppUri = $result.Outputs.webAppUri.value
Write-Host "##vso[task.setvariable variable=Custom.WebAppName;]$webAppName"
