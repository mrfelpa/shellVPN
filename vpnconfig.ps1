import-module VpnClient
import-module VpnGateway


function Validate-XmlSchema {
    param (
        [Parameter(Mandatory)]
        [string] $SchemaPath
    )

    if (-not (Test-Path $SchemaPath)) {
        throw "Schema file not found at $SchemaPath"
    }

    $schema = Get-Content $SchemaPath
    [xml](Get-Content "C:\VPN\VPNConfigurations.xml").Validate($schema)
}


class VpnConnection {
    [string] $Name
    [string] $Protocol
    [string] $LocalGatewayName
    [string] $RemoteGatewayName
    [string] $LocalGatewayIP
    [string] $RemoteGatewayIP
    [string] $SharedKey
    [string] $WireGuardPrivateKey
    [string] $WireGuardPublicKey
    [string] $L2TPUsername
    [string] $L2TPPassword
    [string] $IKEv2SharedKey
    [string] $IKEv2PreSharedKey

    VpnConnection([string] $Name, [string] $Protocol, [string] $LocalGatewayName, [string] $RemoteGatewayName, [string] $LocalGatewayIP, [string] $RemoteGatewayIP, [string] $SharedKey,
                  [string] $WireGuardPrivateKey, [string] $WireGuardPublicKey, [string] $L2TPUsername, [string] $L2TPPassword, [string] $IKEv2SharedKey, [string] $IKEv2PreSharedKey) {
        $this.Name = $Name
        $this.Protocol = $Protocol
        $this.LocalGatewayName = $LocalGatewayName
        $this.RemoteGatewayName = $RemoteGatewayName
        $this.LocalGatewayIP = $LocalGatewayIP
        $this.RemoteGatewayIP = $RemoteGatewayIP
        $this.SharedKey = $SharedKey
        $this.WireGuardPrivateKey = $WireGuardPrivateKey
        $this.WireGuardPublicKey = $WireGuardPublicKey
        $this.L2TPUsername = $L2TPUsername
        $this.L2TPPassword = $L2TPPassword
        $this.IKEv2SharedKey = $IKEv2SharedKey
        $this.IKEv2PreSharedKey = $IKEv2PreSharedKey
    }

    [void] New-VpnConnection() {
        if ($this.Protocol -eq "WireGuard") {
            New-VpnConnection -Name $this.Name -Protocol "WireGuard" -WireGuardPrivateKey $this.WireGuardPrivateKey -WireGuardPublicKey $this.WireGuardPublicKey
        } elseif ($this.Protocol -eq "L2TP/IPsec") {
            New-L2TPVpnConnection -Name $this.Name -RemoteAddress $this.RemoteGatewayIP -Username $this.L2TPUsername -Password $this.L2TPPassword
        } elseif ($this.Protocol -eq "IKEv2/IPsec") {
            New-VpnConnection -Name $this.Name -Protocol "IKEv2/IPsec" -SharedKey $this.IKEv2SharedKey -PreSharedKey $this.IKEv2PreSharedKey
        } else {
            throw "Unsupported VPN protocol: $($this.Protocol)"
        }
    }

    [void] New-VpnConnectionConfiguration([string] $ConfigFileFolder = "C:\VPN\ClientConfigs") {
        New-VpnConnectionConfiguration -Name $this.Name -Protocol $this.Protocol -LocalGatewayName $this.LocalGatewayName -RemoteGatewayName $this.RemoteGatewayName -LocalGatewayIP $this.LocalGatewayIP -RemoteGatewayIP $this.RemoteGatewayIP -SharedKey $this.SharedKey -SavePath $ConfigFileFolder
    }
}


function Create-VpnConnectionsFromXml {
    param (
        [Parameter(Mandatory)]
        [string] $XmlFilePath,
        [string] $ConfigFileFolder = "C:\VPN\ClientConfigs",
        [string] $LogFilePath = "C:\VPN\Logs\VpnConnectionCreation.log"
    )

    Validate-XmlSchema -SchemaPath "C:\VPN\VPNConfigurations.xsd"

    if (-not (Test-Path $XmlFilePath)) {
        Write-Error "XML file not found at $XmlFilePath" -ErrorAction Stop
    }

    if (-not (Test-Path $ConfigFileFolder)) {
        New-Item -ItemType Directory -Path $ConfigFileFolder | Out-Null
    }

    $logFolder = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path $logFolder)) {
        New-Item -ItemType Directory -Path $logFolder | Out-Null
    }

    $configFile = [xml](Get-Content $XmlFilePath)

    foreach ($connection in $configFile.Connection) {
        try {
            
            $vpnConnection = [VpnConnection]::new(
                $connection.Name,
                $connection.Protocol,
                $connection.LocalGatewayName,
                $connection.RemoteGatewayName,
                $connection.LocalGatewayIP,
                $connection.RemoteGatewayIP,
                $connection.SharedKey,
                $connection.WireGuardPrivateKey,
                $connection.WireGuardPublicKey,
                $connection.L2TPUsername,
                $connection.L2TPPassword,
                $connection.IKEv2SharedKey,
                $connection.IKEv2PreSharedKey
            )

            $vpnConnection.New-VpnConnection()
            $vpnConnection.New-VpnConnectionConfiguration($ConfigFileFolder)
        }
        catch {
            Write-Error "Error creating VPN connection for $($connection.Name): $_" -ErrorAction Continue
            Add-Content -Path $LogFilePath -Value "Error creating VPN connection for $($connection.Name): $_"
        }
    }
}