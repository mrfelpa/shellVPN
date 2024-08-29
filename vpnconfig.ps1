import-module VpnClient
import-module VpnGateway
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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

class VpnConnectionForm : System.Windows.Forms.Form {
    [VpnConnection] $VpnConnection
    [System.Windows.Forms.Button] $CreateButton
    [System.Windows.Forms.Button] $SaveButton
    [System.Windows.Forms.TextBox] $NameTextBox
    [System.Windows.Forms.ComboBox] $ProtocolComboBox
    [System.Windows.Forms.TextBox] $LocalGatewayNameTextBox
    [System.Windows.Forms.TextBox] $RemoteGatewayNameTextBox
    [System.Windows.Forms.TextBox] $LocalGatewayIPTextBox
    [System.Windows.Forms.TextBox] $RemoteGatewayIPTextBox
    [System.Windows.Forms.TextBox] $SharedKeyTextBox
    [System.Windows.Forms.TextBox] $WireGuardPrivateKeyTextBox
    [System.Windows.Forms.TextBox] $WireGuardPublicKeyTextBox
    [System.Windows.Forms.TextBox] $L2TPUsernameTextBox
    [System.Windows.Forms.TextBox] $L2TPPasswordTextBox
    [System.Windows.Forms.TextBox] $IKEv2SharedKeyTextBox
    [System.Windows.Forms.TextBox] $IKEv2PreSharedKeyTextBox

    VpnConnectionForm() {
        $this.InitializeComponent()
    }

    hidden [void] InitializeComponent() {
        $this.SuspendLayout()
        
        $this.CreateButton = New-Object System.Windows.Forms.Button
        $this.SaveButton = New-Object System.Windows.Forms.Button
        $this.NameTextBox = New-Object System.Windows.Forms.TextBox
        $this.ProtocolComboBox = New-Object System.Windows.Forms.ComboBox
        $this.LocalGatewayNameTextBox = New-Object System.Windows.Forms.TextBox
        $this.RemoteGatewayNameTextBox = New-Object System.Windows.Forms.TextBox
        $this.LocalGatewayIPTextBox = New-Object System.Windows.Forms.TextBox
        $this.RemoteGatewayIPTextBox = New-Object System.Windows.Forms.TextBox
        $this.SharedKeyTextBox = New-Object System.Windows.Forms.TextBox
        $this.WireGuardPrivateKeyTextBox = New-Object System.Windows.Forms.TextBox
        $this.WireGuardPublicKeyTextBox = New-Object System.Windows.Forms.TextBox
        $this.L2TPUsernameTextBox = New-Object System.Windows.Forms.TextBox
        $this.L2TPPasswordTextBox = New-Object System.Windows.Forms.TextBox
        $this.IKEv2SharedKeyTextBox = New-Object System.Windows.Forms.TextBox
        $this.IKEv2PreSharedKeyTextBox = New-Object System.Windows.Forms.TextBox

        # Set form properties
        $this.Text = "VPN Connection"
        $this.Size = New-Object System.Drawing.Size(600, 500)
        $this.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

        $this.ResumeLayout($false)
    }

    [void] Show() {
        $this.ShowDialog()
    }

    [void] CreateVpnConnection() {
        $this.VpnConnection = [VpnConnection]::new(
            $this.NameTextBox.Text,
            $this.ProtocolComboBox.SelectedItem,
            $this.LocalGatewayNameTextBox.Text,
            $this.RemoteGatewayNameTextBox.Text,
            $this.LocalGatewayIPTextBox.Text,
            $this.RemoteGatewayIPTextBox.Text,
            $this.SharedKeyTextBox.Text,
            $this.WireGuardPrivateKeyTextBox.Text,
            $this.WireGuardPublicKeyTextBox.Text,
            $this.L2TPUsernameTextBox.Text,
            $this.L2TPPasswordTextBox.Text,
            $this.IKEv2SharedKeyTextBox.Text,
            $this.IKEv2PreSharedKeyTextBox.Text
        )

        $this.VpnConnection.New-VpnConnection()
        $this.VpnConnection.New-VpnConnectionConfiguration()
    }

    [void] SaveVpnConnectionToXml() {
        $configFile = [xml](Get-Content "C:\VPN\VPNConfigurations.xml")
        $connectionNode = $configFile.CreateElement("Connection")

        $connectionNode.AppendChild($configFile.CreateElement("Name")).InnerText = $this.VpnConnection.Name
        $connectionNode.AppendChild($configFile.CreateElement("Protocol")).InnerText = $this.VpnConnection.Protocol
        $connectionNode.AppendChild($configFile.CreateElement("LocalGatewayName")).InnerText = $this.VpnConnection.LocalGatewayName
        $connectionNode.AppendChild($configFile.CreateElement("RemoteGatewayName")).InnerText = $this.VpnConnection.RemoteGatewayName
        $connectionNode.AppendChild($configFile.CreateElement("LocalGatewayIP")).InnerText = $this.VpnConnection.LocalGatewayIP
        $connectionNode.AppendChild($configFile.CreateElement("RemoteGatewayIP")).InnerText = $this.VpnConnection.RemoteGatewayIP
        $connectionNode.AppendChild($configFile.CreateElement("SharedKey")).InnerText = $this.VpnConnection.SharedKey
        $connectionNode.AppendChild($configFile.CreateElement("WireGuardPrivateKey")).InnerText = $this.VpnConnection.WireGuardPrivateKey
        $connectionNode.AppendChild($configFile.CreateElement("WireGuardPublicKey")).InnerText = $this.VpnConnection.WireGuardPublicKey
        $connectionNode.AppendChild($configFile.CreateElement("L2TPUsername")).InnerText = $this.VpnConnection.L2TPUsername
        $connectionNode.AppendChild($configFile.CreateElement("L2TPPassword")).InnerText = $this.VpnConnection.L2TPPassword
        $connectionNode.AppendChild($configFile.CreateElement("IKEv2SharedKey")).InnerText = $this.VpnConnection.IKEv2SharedKey
        $connectionNode.AppendChild($configFile.CreateElement("IKEv2PreSharedKey")).InnerText = $this.VpnConnection.IKEv2PreSharedKey

        $configFile.DocumentElement.AppendChild($connectionNode)
        $configFile.Save("C:\VPN\VPNConfigurations.xml")
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

$form = [VpnConnectionForm]::new()
$form.Show()
