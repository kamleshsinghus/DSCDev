function Get-TargetResource
{
    [CmdletBinding()] 
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source,
        [parameter(Mandatory = $false)]		
        [System.Boolean]
        $Preview = $false,
        [parameter(Mandatory = $false)]		
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    "Checking chocolatey installed" | Write-Verbose

    CheckChocoInstalled

	"Getting configuration" | Write-Verbose
    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        Name = $Name
        Params = $Params
        Version = $Version
		Source = $Source
		Preview = $Preview
		Ensure = $Ensure
    }

    return $Configuration
}

function Set-TargetResource
{
    [CmdletBinding()]    
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,   
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,   
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source,	
        [parameter(Mandatory = $false)]	
        [System.Boolean]
        $Preview = $false,	
        [parameter(Mandatory = $false)]	
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"

    )
    
    CheckChocoInstalled

	if($Ensure -eq "Present")
	{
		if ($Source)
		{
			$SourceCmdOutput = choco source remove -n="$Name"
			$SourceCmdOutput += choco source add -n="$Name" -s="$Source"
			"Source command output: $SourceCmdOutput" | Write-Verbose
		}

		"Starting chocolatey package - $Name installation" | Write-Verbose

		if($Preview)
		{
			$Name = "$Name -pre"
		}

		InstallPackage -pName $Name -pParams $Params -pVersion $Version
		"Successfully completed installation of chocolatey package $Name" | Write-Verbose
	}	
	else
	{
		"Starting chocolatey package - $Name uninstallation" | Write-Verbose
			
		UninstallPackage $Name
		"Successfully completed chocolatey package $Name removal" | Write-Verbose
	}
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source,		
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Preview = $false,		
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )
	
    CheckChocoInstalled

	if	( `
			(-not $Version) -and -not (IsPackageInstalled $Name) `
			-or `
			($Version) -and -not (IsPackageInstalled -pName $Name -pVersion $Version) `
	)
    {
		if($Ensure -eq "Present")
		{
			"The chocolatey package $Name is not installed on the machine" | Write-Verbose
			"This will be installed" | Write-Verbose
			return $false
		}
		else
		{
			"The chocolatey package $Name is not installed on the machine" | Write-Verbose
			"Skipping removal of package" | Write-Verbose
			return $true
		}
    }
	else
	{
		if($Ensure -eq "Absent")
		{
			"The chocolatey package $Name is installed on the machine" | Write-Verbose
			"This will be removed" | Write-Verbose
			return $false
		}
		else
		{
			"The chocolatey package $Name is installed on the machine" | Write-Verbose
			"Skipping package installation" | Write-Verbose
			return $true
		}
	}
}


function CheckChocoInstalled
{
    if (-not (DoesCommandExist choco))
    {
        throw "pChocoPackage requires Chocolatey to be installed, consider using pChocoInstall with 'dependson' in dsc configuration"
    }
}

function InstallPackage
{
    param
	(
        [Parameter(Position=0,Mandatory=1)]
		[string]$pName,

        [Parameter(Position=1,Mandatory=0)]
		[string]$pParams,

        [Parameter(Position=2,Mandatory=0)]
		[string]$pVersion
    ) 

    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine')
    
    if ((-not ($pParams)) -and (-not $pVersion))
    {
        "Installing chocolatey package $pName with standard options" | Write-Verbose
        $packageInstallOuput = choco install $pName -y
    }
    elseif ($pParams -and $pVersion)
    {
        Write-Verbose "Installing Package with Params $pParams and Version $pVersion"
        $packageInstallOuput = choco install $pName --params="$pParams" --version=$pVersion -y        
    }
    elseif ($pParams)
    {
        Write-Verbose "Installing Package with params $pParams"
        $packageInstallOuput = choco install $pName --params="$pParams" -y            
    }
    elseif ($pVersion)
    {
        Write-Verbose "Installing Package with version $pVersion"
        $packageInstallOuput = choco install $pName --version=$pVersion -y        
    }
    
    
    Write-Verbose "Chocolatey output: $packageInstallOuput "

    #refresh path varaible in powershell, as choco doesn"t, to pull in git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function UninstallPackage
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)]
		[System.String] $Name
	)

	"Uninstalling chocolatey package $Name" | Write-Verbose
	$output = choco uninstall $Name -y
	"Chocolatey output : $output" | Write-Verbose
}


function IsPackageInstalled
{
    param
	(
        [Parameter(Position=0,Mandatory=1)]
		[string]$pName,
        [Parameter(Position=1,Mandatory=0)]
		[string]$pVersion
    ) 

	"Checking $pName chocolatey package installed on machine" | Write-Verbose

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

	if ($pVersion) 
	{
		$installedPackages = choco list -lo | Where-object { $_.ToLower().Contains($pName.ToLower()) -and $_.ToLower().Contains($pVersion.ToLower()) }
	} 
	else 
	{
		$installedPackages = choco list -lo | Where-object { $_.ToLower().Contains($pName.ToLower()) }
	}
	
    if ($installedPackages.Count -gt 0)
    {
        return $true
    }

    return $false
    
}

function DoesCommandExist
{
    param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'

    try 
    {
        if(Get-Command $command)
        {
            return $true
        }
    }
    catch 
    {
        return $false
    }
    finally 
	{
        $ErrorActionPreference=$oldPreference
    }
} 


##region - chocolately installer work arounds. Main issue is use of write-host
##attempting to work around the issues with Chocolatey calling Write-host in its scripts. 
function global:Write-Host
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Object]
        $Object,
        [Switch]
        $NoNewLine,
        [ConsoleColor]
        $ForegroundColor,
        [ConsoleColor]
        $BackgroundColor

    )

    #Override default Write-Host...
    Write-Verbose $Object
}

Export-ModuleMember -Function *-TargetResource