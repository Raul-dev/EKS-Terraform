# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2021 Raul
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#./terra.ps1 -action  $region $autoapply $breconfigure
#./terra.ps1 init us-west-2
Param (
    [parameter(Mandatory=$true)][string]$action="",
    [parameter(Mandatory=$false)][string]$region="us-west-2",
	[parameter(Mandatory=$false)][string]$environment="dev",
    [parameter(Mandatory=$false)][bool]$autoapply=$True,
    [parameter(Mandatory=$false)][bool]$breconfigure=$False    
)
Write-Host "********************************************************"  
Write-Host "Region:     "$region -fore green
Write-Host "Terraform:  "$action -fore green


$BasePath = Convert-Path ..\..

$tmppath=$BasePath+"\secret"
$UsedPrivateVariable=$BasePath + "\secret\varprivate.txt"
if (-Not (Test-Path -Path $tmppath)){
    New-Item -Path $BasePath -Name "secret" -ItemType "directory"
    $tmpname = $tmppath+"\CourseEKS-BNS-01-dev"
    ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f $tmpname
    $tmpname = $tmppath+"\CourseEKS-BNS-01-production"
    ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f $tmpname
    $tmpname = $tmppath+"\CourseEKS-BNS-01-staging"
    ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f $tmpname
    
    Add-Content -Path $UsedPrivateVariable -Value ("REPO_NAME=[""testimage""]")
    Add-Content -Path $UsedPrivateVariable -Value ("PROFILE=""YourAwsProfile""")
    Add-Content -Path $UsedPrivateVariable -Value ("INGRES_SCIDR_BLOCK=[""195.216.214.01""]")
    Add-Content -Path $UsedPrivateVariable -Value ("OWNER=""YourName""")


    Set-Location $tmppath
}

$backendpath=$BasePath+"\secret\"+$region
if (-Not (Test-Path -Path $backendpath)){
    New-Item -Path $BasePath"\secret\" -Name $region -ItemType "directory"
}

$backend_path = $backendpath +"\terraform_"+$region+".tfstate"
$backend="-backend-config=""path="+$backend_path+""""
Write-Host $backend 

$BasicVariable =  $BasePath + "\env\"+ $environment+"\varprj.txt"
Write-Host "Variable get from: "$BasicVariable


$UsedVariable=$BasePath + "\secret\"+$region+"\init-variable.txt"
Write-Host "Used Variable : "$UsedVariable
$sautoapply =""
if($autoapply){
    $sautoapply = "-auto-approve"
}
$LastVariable=$BasePath + "\secret\"+$region+"\"+$environment+"-init-variable-last.txt"


Remove-Item -Path $UsedVariable -Force -ErrorAction SilentlyContinue
try {
    Add-Content -Path $UsedVariable -Value (Get-Content -Path $BasicVariable)
    Add-Content -Path $UsedVariable -Value ("AWS_REGION=""$region""")
    Add-Content -Path $UsedVariable -Value ("ENV=""$environment""")
    Add-Content -Path $UsedVariable -Value (Get-Content -Path $UsedPrivateVariable)
    
    
 
    # Destroy s3
    # terraform destroy -var-file=$UsedVariable -backup=".\us-east-2\terra-us-east-2.backup"
    # terraform init -var-file=$UsedVariable -backend-config="path=.\us-east-2\terraform_us-east-2.tfstate" -state=.\us-east-2\terrastate_us-east-2.tfstate
    switch($action) {
        "init" {
            Write-Host  "init"
            Write-Host $UsedVariable
            terraform $action -var-file="$UsedVariable" -reconfigure $backend
            
        }

        "apply" {
            Write-Host  "apply"
            terraform init -var-file="$UsedVariable" -reconfigure $backend
            terraform $action -var-file="$UsedVariable" $sautoapply
            Remove-Item -Path $LastVariable -Force -ErrorAction SilentlyContinue
            Add-Content -Path $LastVariable -Value (Get-Content -Path $UsedVariable)
            
        }

        "destroy" {
            Write-Host  "init"
            terraform init -var-file="$UsedVariable" -reconfigure $backend
            Write-Host  "destroy"
            terraform $action -var-file="$UsedVariable" $sautoapply
            Remove-Item -Path $LastVariable -Force -ErrorAction SilentlyContinue
        }
        default {
            Write-Host  $action + " Wrong action" -fore red
            terraform $action -var-file="$UsedVariable"
            
        }
    }
}
catch {
  
  Write-Host "An error occurred:" -fore red
  Write-Host $_ -fore red
  Write-Host "Stack:"
  Write-Host $_.ScriptStackTrace
  Exit 1
}

Remove-Item -Path $UsedVariable -Force -ErrorAction SilentlyContinue
