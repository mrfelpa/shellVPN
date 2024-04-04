import-module VpnClient
import-module VpnGateway

# Function to validate the XML schema
function Validate-XmlSchema {
    param (
        [Parameter(Mandatory)]
        [string] $SchemaPath
    )

    test-path $SchemaPath

    $schema = get-content $SchemaPath

    [xml](get-content "C:\VPN\VPNConfigurations.xml").Validate($schema)
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
    [string] $WireGuardPrivateKey
    [string] $WireGuardPublicKey
    [string] $L2TPUsername
    [string] $L2TPPassword
    [string] $IKEv2SharedKey
    [string] $IKEv2PreSharedKey

    [CmdletBinding()]
    public VpnConnection([string] $Name, [string] $Protocol, [string] $LocalGatewayName, [string] $RemoteGatewayName, [string] $LocalGatewayIP, [string] $RemoteGatewayIP, [string] $SharedKey,
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

    public New-VpnConnection() {
        if ($this.Protocol == "WireGuard") {
            New-VpnConnection -Name $this.Name -Protocol "WireGuard" -WireGuardPrivateKey $this.WireGuardPrivateKey -WireGuardPublicKey $this.WireGuardPublicKey
        } elseif ($this.Protocol == "L2TP/IPsec") {
            New-L2TPVpnConnection -Name $this.Name -RemoteAddress $this.RemoteGatewayIP -Username $this.L2TPUsername -Password $this.L2TPPassword
        } elseif ($this.Protocol == "IKEv2/IPsec") {
            New-VpnConnection -Name $this.Name -Protocol "IKEv2/IPsec" -SharedKey $this.IKEv2SharedKey -PreSharedKey $this.IKEv2PreSharedKey
        }
    }

    public New-VpnConnectionConfiguration() {
        New-VpnConnectionConfiguration -Name $this.Name -Protocol $this.Protocol -LocalGatewayName $this.LocalGatewayName -RemoteGatewayName $this.RemoteGatewayName -LocalGatewayIP $this.LocalGatewayIP -RemoteGatewayIP $this.RemoteGatewayIP -SharedKey $this.SharedKey -SavePath $this.ConfigFileFolder
    }
}

# Function to create VPN connections from an XML file
function Create-VpnConnectionsFromXml {
    param (
        [Parameter(Mandatory)]
        [string] $XmlFilePath,
        [string] $ConfigFileFolder = "C:\VPN\ClientConfigs"
    )

   # Validate the XML schema

    Validate-XmlSchema "C:\VPN\VPNConfigurations.xsd"

    $configFile = [xml](get-content $XmlFilePath)

    foreach ($connection in $configFile.Connection) {
        # Create a new instance of the VpnConnection class
        $vpnConnection = new-object VpnConnection $connection.Name $connection.Protocol $connection.LocalGatewayName $connection.RemoteGatewayName $connection.LocalGatewayIP $connection.RemoteGatewayIP $connection.SharedKey $connection.WireGuardPrivateKey $connection.WireGuardPublicKey $connection.L2TPUsername
