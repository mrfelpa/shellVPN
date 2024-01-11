
Import-Module VpnClientConfiguration
Import-Module VpnGateway

# Function to validate the XML schema
function Validate-XmlSchema {
    param (
        [Parameter(Mandatory)]
        [string] $SchemaPath
    )

    # Check if the file exists
    Test-Path $SchemaPath

    $schema = Get-Content $SchemaPath

    [xml](Get-Content "C:\VPN\VPNConfigurations.xml").Validate($schema)
}

# Function to create VPN connections
class VpnConnection {
    [string] $Name
    [string] $Protocol
    [string] $LocalGatewayName
    [string] $RemoteGatewayName
    [string] $LocalGatewayIP
    [string] $RemoteGatewayIP
    [string] $SharedKey

    [CmdletBinding()]
    public VpnConnection([string] $Name, [string] $Protocol, [string] $LocalGatewayName, [string] $RemoteGatewayName, [string] $LocalGatewayIP, [string] $RemoteGatewayIP, [string] $SharedKey) {
        $this.Name = $Name
        $this.Protocol = $Protocol
        $this.LocalGatewayName = $LocalGatewayName
        $this.RemoteGatewayName = $RemoteGatewayName
        $this.LocalGatewayIP = $LocalGatewayIP
        $this.RemoteGatewayIP = $RemoteGatewayIP
        $this.SharedKey = $SharedKey
    }

    public New-VpnConnection() {
        New-VpnConnection -Name $this.Name -Protocol $this.Protocol -LocalGatewayName $this.LocalGatewayName -RemoteGatewayName $this.RemoteGatewayName -LocalGatewayIP $this.LocalGatewayIP -RemoteGatewayIP $this.RemoteGatewayIP -SharedKey $this.SharedKey
    }

    public New-VpnConnectionConfiguration() {
        New-VpnConnectionConfiguration -Name $this.Name -Protocol $this.Protocol -LocalGatewayName $this.LocalGatewayName -RemoteGatewayName $this.RemoteGatewayName -LocalGatewayIP $this.LocalGatewayIP -RemoteGatewayIP $this.RemoteGatewayIP -SharedKey $this.SharedKey -SavePath $this.ConfigFileFolder
    }
}

function Create-VpnConnectionsFromXml {
    param (
        [Parameter(Mandatory)]
        [string] $XmlFilePath,
        [string] $ConfigFileFolder = "C:\VPN\ClientConfigs"
    )

    # Validate the XML schema

    Validate-XmlSchema "C:\VPN\VPNConfigurations.xsd"

    $configFile = [xml](Get-Content $XmlFilePath)

    foreach ($connection in $configFile.Connection) {
       # Create a new instance of the VpnConnection class
        $vpnConnection = new-object VpnConnection $connection.Name $connection.Protocol $connection.LocalGatewayName $connection.RemoteGatewayName $connection.LocalGatewayIP $connection.RemoteGatewayIP $connection.SharedKey

        # Create the VPN connection
        $vpnConnection.New-VpnConnection()

        # Create VPN client configuration file
        $vpnConnection.New-VpnConnectionConfiguration()
    }
}

# Call the function to create VPN connections
Create-VpnConnectionsFromXml "C:\VPN\VPNConfigurations.xml"
