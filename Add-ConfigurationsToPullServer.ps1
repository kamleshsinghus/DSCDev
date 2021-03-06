$tempConfigPath = Join-Path $env:TEMP "PullConfigurations"
if(-not(Test-Path $tempConfigPath -ErrorAction SilentlyContinue)){
    New-Item -ItemType Directory -Force $tempConfigPath
}

$baseConfigFolder = Join-Path $tempConfigPath 'BaseConfig'
$chocoConfigFolder = Join-Path $tempConfigPath 'ChocoConfig'

.\BaseModuleConfig -Path $baseConfigFolder
.\ChocoPackageConfig -Path $chocoConfigFolder

"Creating checksum file at location $baseConfigFolder" | Write-Host
New-DscChecksum -ConfigurationPath $baseConfigFolder -OutPath $baseConfigFolder -Verbose -Force
"Creating checksum file at location $chocoConfigFolder" | Write-Host
New-DscChecksum -ConfigurationPath $chocoConfigFolder -OutPath $chocoConfigFolder -Verbose -Force


$configUploadFolder = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration\"
"Copying the configuration and checksum files to $configUploadFolder" | Write-Host
Copy-Item -Path "$baseConfigFolder\*" -Destination $configUploadFolder
Copy-Item -Path "$chocoConfigFolder\*" -Destination $configUploadFolder