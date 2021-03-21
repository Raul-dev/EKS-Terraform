# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2021 Raul
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#./terra.ps1 -action  $region $environment $autoapply $breconfigure
Param (
    [parameter(Mandatory=$true)][string]$action="",
    [parameter(Mandatory=$false)][string]$region="us-west-2",
	[parameter(Mandatory=$false)][string]$environment="dev",
    [parameter(Mandatory=$false)][bool]$autoapply=$False,
    [parameter(Mandatory=$false)][bool]$breconfigure=$False    
)
$s3stapname="20_bastion"
Write-Host "********************************************************"  
Write-Host "Region:     "$region -fore green
Write-Host "Terraform:  "$action -fore green


$backend_path = ".\"+$region+"\terraform_"+$region+".tfstate"
$backend="-backend-config=""path="+$backend_path+""""
Write-Host $backend 

$BasePath = Convert-Path ..\..
$BasicVariable =  $BasePath + "\env\"+ $environment+"\varprj.txt"
Write-Host "Variable get from: "$BasicVariable


$UsedVariable=$BasePath + "\secret\"+$region+"\"+$environment+"-"+$s3stapname+"-variable.txt"
Write-Host "Used Variable : "$UsedVariable

[string] $BackendName = Get-Content -Path $BasicVariable | Select-String -Pattern 'BACKENDNAME' -CaseSensitive -Exclude 'BACKENDNAME='
$BackendName=$BackendName.Substring(13).Remove($BackendName.Length-14,1)
$BackendName = $BackendName+"-"+$region
Write-Host "BackendName:"$BackendName -fore green 
$s3stapname=$s3stapname+"-"+$region+"-"+$environment
Write-Host "Backend file:"$s3stapname -fore green 
$sautoapply =""
if($autoapply -AND $action -notmatch "init"){
    $sautoapply = "-auto-approve"
}
Write-Host "Auto apply: "$autoapply -fore green
$UsedPrivateVariable=$BasePath + "\secret\varprivate.txt"
Remove-Item -Path $UsedVariable -Force -ErrorAction SilentlyContinue
try {
	Add-Content -Path $UsedVariable -Value (Get-Content -Path $BasicVariable)
	Add-Content -Path $UsedVariable -Value (Get-Content -Path $UsedPrivateVariable)
	Add-Content -Path $UsedVariable -Value ("AWS_REGION=""$region""")
    Add-Content -Path $UsedVariable -Value ("ENV=""$environment""")

	#if($breconfigure -OR $action -match "init") {
	  $Back1 = "-backend-config=""bucket="+$BackendName+""""  
	  $Back2 = "-backend-config=""key="+$s3stapname+".tfstate"""
	  $Back3 = "-backend-config=""region="+$region+""""
	  #local
	  #$Back1 = ""  
	  #$Back2 = "-backend-config=""path=..\..\secret\"+$region+"\"+$s3stapname+".tfstate"""
	  #$Back3 = "-backend-config=""workspace_dir="+$BasePath + "\secret"""
	  #terraform init -var-file="dev-init-variable-last.txt" -backend-config="workspace_dir=C:\work\CourseEKS\EKS-Terraform\secret" -backend-config="path=20-test-us-east-2-dev-us-east-2.tfstate"
	  #-backend-config="bucket=terra-s3backend-smpl" -backend-config="key=10_vpc-privus-west-2.tfstate" -backend-config="region=us-west-2"
	  Write-Host $Back1
	  Write-Host $Back2
	  Write-Host $Back3
	  Write-Host $sautoapply
	  terraform "init" -var-file="$UsedVariable" -reconfigure $Back1 $Back2 $Back3   -backend=true -force-copy -get=true -input=false 
	#}
	if($action -notmatch "init") {
		
	  terraform $action -var-file="$UsedVariable" $sautoapply
	}
}
catch {
  
  Write-Host "An error occurred:" -fore red
  Write-Host $_ -fore red
  Write-Host "Stack:"
  Write-Host $_.ScriptStackTrace
}

#Remove-Item -Path $UsedVariable -Force -ErrorAction SilentlyContinue
