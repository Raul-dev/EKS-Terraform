# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2021 Raul
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#./createterra.ps1 -action init
# ./createterra.ps1 -action init -environment dev -region us-east-2 -step All -action init

Param (
  [parameter(Mandatory=$true)][string]$action="",
  [parameter(Mandatory=$false)][string]$environment="dev",
  [parameter(Mandatory=$false)][ValidateSet("All","00_init","10_vpc","20_bastion","30_registry","40_kubernates","50_elk",IgnoreCase=$true)]$step="All",
  [parameter(Mandatory=$false)][ValidateSet("All","us-east-2","us-west-2",IgnoreCase=$true)]$region="us-west-2"

)

function ExecTerraform {

  param (
      $folder,
      $action,
      $region,
	  $environment,
      $autoapply,
      $breconfigure
  )
  $var=Get-Location
  Write-Host "Current dir"$var
  Write-Host "Worked dir: "$folder
  
  


  Set-Location $folder

  try{
  ./terra.ps1 $action $region $environment $autoapply $breconfigure
  } catch { 
    Write-Host "ExecTerraform: An terraform error occurred "$folder$action -fore red
    Write-Host $_ -fore red
  
  }
  

  
  Set-Location $var
  Write-Host "Finish Current dir"$var
}
terraform -v            # Tested on version v0.14.4

$profile="mfa"          #aws cli profile
$destroys3=$false
$autoapply =$true
Write-Host "Region:     "$region -fore green
Write-Host "Step:       "$step -fore green
Write-Host "Terraform:  "$action -fore green
$s3found = ""

$BasePath = Convert-Path ..
$BasicVariable =  $BasePath + "\env\"+ $environment+"\varprj.txt"
Write-Host "Variable get from: "$BasicVariable

$UsedVariable=$BasePath + "\secret\"+ $region+"\10-vpc-variable.txt"
Write-Host "Used Variable : "$UsedVariable

[string] $BackendName = Get-Content -Path $BasicVariable | Select-String -Pattern 'BACKENDNAME' -CaseSensitive -Exclude 'BACKENDNAME='
$BackendName=$BackendName.Substring(13).Remove($BackendName.Length-14,1)
$BackendName = $BackendName+"-"+$region
Write-Host "BackendName:"$BackendName -fore green 

$LastVariable=$BasePath + "\secret\"+ $region+"\"+$environment+"-init-variable-last.txt"
Write-Host $LastVariable

[string] $reconfigure = Get-Content -Path $LastVariable -ErrorAction SilentlyContinue | Select-String -Pattern 'AWS_REGION' -CaseSensitive 
$reconfigure=$reconfigure.Substring(11).Remove($reconfigure.Length-12,1)

Write-Host "OLD_AWS_REGION:"$reconfigure -fore green  
[bool]$breconfigure=$false
if($reconfigure -notmatch $region){
  $breconfigure =$true
}
Write-Host "reconfigure:"$breconfigure -fore green  
[string]$s3found = aws s3 ls --profile $profile | Select-String -Pattern $BackendName.Trim() -CaseSensitive
#aws s3 ls --profile mfa | Select-String -Pattern 'terra-s3backend-us-west-2' -CaseSensitive

if($s3found.Contains($BackendName) ) {
  Write-Host "S3 backend: "$s3found -fore green  
} else {
  Write-Host "S3 backend: "$BackendName" not found. This will be created." -fore yellow  
}

Write-Host "Auto apply: "$autoapply -fore green



try {


#Apply All directories
#$Dirs = Get-ChildItem . -Directory 
#Apply only selected directories in list
$Dirs = ("00_init","10_vpc") #Exclude kubernates cluster
Write-Host "Steps: "$Dirs

for ($i=0; $i -lt $Dirs.count; $i++){
  if($action -match "destroy")  {
    $Dir = $Dirs[$Dirs.count - $i -1]
    Write-Host "Step: "$Dir 
  } else {
    $Dir = $Dirs[$i]
    Write-Host "Step: "$Dir 
  }

  if($step -notmatch "All" -AND $step -notmatch $Dir ){
    continue
  }

  if($Dir -match "00_init"  ) {
    if($s3found.Contains($BackendName) -AND -NOT($action -match "destroy" -AND $destroys3)) {
      Write-Host "Step skipped "
      continue
      
    }
    if($action -match "init" -OR $action -match "apply"){
      ExecTerraform $Dir "apply" $region $environment $autoapply $breconfigure
    }
    if($action -match "destroy" -AND $destroys3){
      ExecTerraform $Dir "destroy" $region $environment $autoapply $breconfigure
    }
    
  } else {
     ExecTerraform $Dir $action $region $environment $autoapply $breconfigure
  }

#  Write-Host "Read and Convert $($File.Name)" -ForegroundColor Cyan
#  Get-Content $File.FullName  | Set-Content -Encoding $Encoding ($DestinationPath + $File.Name) -Force -Confirm:$false
#  Remove-Item –path $SourcePath* -include *.xml –recurse -force

}

# Get-ChildItem -Path C:\Windows\System32\*.txt -Recurse | Select-String -Pattern 'terra-s3backend-smpl' -CaseSensitive
# aws s3api head-bucket --bucket terraformbackend
# aws s3 ls
}
catch {
  
  Write-Host "An error occurred:" -fore red
  Write-Host $_ -fore red
  Write-Host "Stack:"
  Write-Host $_.ScriptStackTrace
}

#$Files = Get-ChildItem $SourcePath -include *.xml -Recurse 
#ForEach ($File in $Files) {
#  Write-Host "Read and Convert $($File.Name)" -ForegroundColor Cyan
#  Get-Content $File.FullName  | Set-Content -Encoding $Encoding ($DestinationPath + $File.Name) -Force -Confirm:$false
#  Remove-Item –path $SourcePath* -include *.xml –recurse -force
#}
