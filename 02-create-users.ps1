# 1. Crééation des OU

Import-Module ActiveDirectory

$ouBase = 'OU=Isitech,DC=isitech,DC=local'
$ouUsers = "OU=Utilisateurs,$ouBase"
$ouGroups = "OU=Groupes,$ouBase"

# Création des OU (idempotent — l'enchaînement relance sans erreur)
foreach ($ou in @($ouBase, $ouUsers, $ouGroups)) {
    $exists = Get-ADOrganizationalUnit `
        -Filter "DistinguishedName -eq '$ou'" `
        -ErrorAction SilentlyContinue

    if (-not $exists) {
        $parts = $ou -split ',', 2
        $name = ($parts[0] -split '=')[1]
        $path = $parts[1]
        
        New-ADOrganizationalUnit -Name $name -Path $path
    }
}

foreach ($dept in 'RH', 'IT', 'Direction') {
    $groupName = "GRP-$dept"
    $exists = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue

    if (-not $exists) {
        New-ADGroup `
            -Name $groupName `
            -GroupScope Global `
            -GroupCategory Security `
            -Path $ouGroups
    }
}

# 2. Création des utilisateurs depuis le CSV
# 2.1. Chargement des données

$users = Import-Csv -Path 'C:\Users\ISITECH\Desktop\atelier02-ad\users.csv' -Delimiter ';' -Encoding UTF8

# 2.2. Traitement des utilisateurs
foreach ($u in $users) {
    
    # Vérification de l'existence

    if (Get-ADUser -Filter "SamAccountName -eq '$($u.login)'" -ErrorAction SilentlyContinue) {
        Write-Host "Skip $($u.login) (deja present)" -ForegroundColor Yellow
        continue
    }

    # Création de l'objet utilisateur

    New-ADUser `
        -Name "$($u.firstName) $($u.lastName)" `
        -GivenName $u.firstName `
        -Surname $u.lastName `
        -SamAccountName $u.login `
        -UserPrincipalName "$($u.login)@isitech.local" `
        -Department $u.department `
        -Title $u.jobTitle `
        -Path $ouUsers `
        -AccountPassword (ConvertTo-SecureString 'isitech!2026' -AsPlainText -Force) `
        -ChangePasswordAtLogon $true `
        -Enabled $true

    # Ajout au groupe de sécurité

    Add-ADGroupMember -Identity "GRP-$($u.department)" -Members $u.login
}

# 3. Vérification 

# 3.1. Lister les utilisateurs créés dans l'OU spécifique
Get-ADUser -Filter * -SearchBase 'OU=Utilisateurs,OU=Isitech,DC=isitech,DC=local' | 
    Select-Object Name, SamAccountName, Department, Enabled

# 3.2. Compter les membres de chaque groupe
foreach ($g in 'GRP-RH', 'GRP-IT', 'GRP-Direction') {
    $count = (Get-ADGroupMember -Identity $g).Count
    Write-Host "$g : $count membres"
}

# 4. Autorisation du serveur DHCP

# Autoriser SRV-LAB comme serveur DHCP de la forêt
Add-DhcpServerInDC -DnsName 'SRV_LAB.isitech.local' -IPAddress '192.168.79.3'

# Vérifier la liste des serveurs DHCP autorisés dans AD
Get-DhcpServerInDC

# Redémarrer le service DHCP pour qu'il prenne en compte l'autorisation
Restart-Service DHCPServer