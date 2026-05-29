Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Construction de la fenêtre principale
$form = New-Object System.Windows.Forms.Form
$form.Text = "Configuration Serveur" 
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(300, 250) # Ajouté pour donner de l'espace aux boutons

#Construction des boutons

#1. Construction du bouton DHCP
$buttonsDhcp = New-Object System.Windows.Forms.Button
$buttonsDhcp.Text = "Ajout DHCP"
$buttonsDhcp.Location = New-Object System.Drawing.Point(50, 20) # Corrigé : Positionnement initial
$buttonsDhcp.Size = New-Object System.Drawing.Size(180, 30)     # Corrigé : Taille pour afficher le texte
$buttonsDhcp.Add_Click({
        [string]$scopeName = 'IsitechLocal'
        [string]$start = '192.168.79.40'
        [string]$stop = '192.168.79.90'
        [string]$mask = '255.255.255.0'
        [int]$day = 8
        [string]$dns = [Microsoft.VisualBasic.Interaction]::InputBox( # Corrigé : Majuscule à VisualBasic
        "Veuillez saisir le DNS", "DHCP", "8.8.8.8"
)
        [string]$domain = 'isitech.local'
        [string]$router = '192.168.79.2'

        Install-WindowsFeature -Name DHCP -IncludeManagementTools -Restart:$false -Verbose
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12' -Name ConfigurationState -Value 2
        Add-DhcpServerv4Scope -Name $scopeName -StartRange $start -EndRange $stop -SubnetMask $mask -LeaseDuration (New-TimeSpan -Days $day) -State Active
        Set-DhcpServerv4OptionValue -DnsServer $dns -DnsDomain $domain -Router $router
})

# 2. Construction du bouton Renommer
$buttonRename = New-Object System.Windows.Forms.Button
$buttonRename.Text = "Renommer Serveur"
$buttonRename.Location = New-Object System.Drawing.Point(50, 70) # Corrigé : Positionnement pour éviter la superposition
$buttonRename.Size = New-Object System.Drawing.Size(180, 30)     # Corrigé : Taille pour afficher le texte
$buttonRename.Add_Click({

    #On remplace Read-Host par une InputBox (partie graphique)
    [string]$nomSRV = [Microsoft.VisualBasic.Interaction]::InputBox( # Corrigé : Remplacement de [Microsoft.Visual.Interaction] par [Microsoft.VisualBasic.Interaction]
        "veuillez saisir le nouveau Nom : ", "Renommer"
    )
    Rename-Computer -NewName $nomSRV -Restart
})

# 3. Construction du bouton AD DS
$buttonAD = New-Object System.Windows.Forms.Button
$buttonAD.Text = "Installation AD DS"
$buttonAD.Location = New-Object System.Drawing.Point(50, 120)    # Ajusté : Positionnement
$buttonAD.Size = New-Object System.Drawing.Size(180, 30)         # Corrigé : Taille pour afficher le texte
$buttonAD.Add_Click({
    # Saisie du mot de passe via InputBox pour l'interface graphique
    [string]$passwordNonCrypte = [Microsoft.VisualBasic.Interaction]::InputBox("Veuillez saisir le mot de passe DSRM", "AD DS")
    $password = ConvertTo-SecureString $passwordNonCrypte -AsPlainText -Force
    
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart:$false -Verbose
    Install-ADDSForest `
        -DomainName 'isitech.local' `
        -DomainNetbiosName 'ISITECH' `
        -SafeModeAdministratorPassword $password `
        -InstallDns `
        -NoRebootOnCompletion:$false `
        -Force
})

# Ajout des contrôles au formulaire
$form.Controls.Add($buttonsDhcp) # Corrigé : Le nom de la variable était $buttonsDhcp au lieu de $buttonDhcp
$form.Controls.Add($buttonRename)
$form.Controls.Add($buttonAD)

# Affichage de la fenêtre 
$form.ShowDialog()
