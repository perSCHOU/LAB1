param (
    [Parameter(Mandatory)]
    [string]$domain,

    [Parameter(Mandatory)]
    [string]$password

)

$ErrorActionPreference = "Stop"

$completeFile="c:\temp\prereqsComplete"
if (!(Test-Path -Path "c:\temp")) {
    md "c:\temp"
}

if (!(Test-Path -Path "$($completeFile)0")) {
    $smPassword = (ConvertTo-SecureString $password -AsPlainText -Force)

    #Install AD, reconfig network
    Install-WindowsFeature -Name "AD-Domain-Services" `
                           -IncludeManagementTools `
                           -IncludeAllSubFeature 

    Install-ADDSForest -DomainName $domain `
                       -DomainMode Win2012 `
                       -ForestMode Win2012 `
                       -Force `
                       -SafeModeAdministratorPassword $smPassword 

    #record that we got this far
    New-Item -ItemType file "$($completeFile)0"
}

if (!(Test-Path -Path "$($completeFile)1")) {
    $Dns = "127.0.0.1"
    $IPType = "IPv4"

    # Retrieve the network adapter that you want to configure
    $adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
    $cfg = ($adapter | Get-NetIPConfiguration)
    $IP = $cfg.IPv4Address.IPAddress
    $Gateway = $cfg.IPv4DefaultGateway.NextHop
    $MaskBits = $cfg.IPv4Address.PrefixLength

    # Remove any existing IP, gateway from our ipv4 adapter
    If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
        $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
    }

    If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
        $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
    }

    #record that we got this far
    New-Item -ItemType file "$($completeFile)1"
}

if (!(Test-Path -Path "$($completeFile)2")) {
    # Configure the IP address and default gateway
    $adapter | New-NetIPAddress `
        -AddressFamily $IPType `
        -IPAddress $IP `
        -PrefixLength $MaskBits `
        -DefaultGateway $Gateway

    # Configure the DNS client server IP addresses
    $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS

    #record that we got this far
    New-Item -ItemType file "$($completeFile)2"
}

if (!(Test-Path -Path "$($completeFile)3")) {
    # Install AAD Tools
	md c:\temp -ErrorAction Ignore
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
	Save-Module -Name MSOnline -Path c:\temp
	Install-Module -Name MSOnline -Force

	Save-Module -Name AzureAD -Path c:\temp
	Install-Module -Name AzureAD -Force

	Save-Module -Name AzureADPreview -Path c:\temp
	Install-Module -Name AzureADPreview -AllowClobber -Force

    #record that we got this far
    New-Item -ItemType file "$($completeFile)3"

}
