do {
    Write-Host "========================================="
    Write-Host "================== MENU ================="
    Write-Host "========================================="
    Write-Host "1 - Ajout et configuration du role DHCP"
    Write-Host "2 - Renommer le serveur"
    Write-Host "3 - Installer et configurer AD DS"

    [int]$choix = Read-Host "Veuillez faire un choix"

    if ($choix -eq 1) {
        [string]$scopeName = 'IsitechLocal'
        [string]$start = '192.168.79.40'
        [string]$stop = '192.168.79.90'
        [string]$mask = '255.255.255.0'
        [int]$day = 8
        [string]$dns = Read-Host "Veuillez saisir le serveur DNS"
        [string]$domain = 'isitech.local'
        [string]$router = '192.168.79.2'

        Install-WindowsFeature -Name DHCP -IncludeManagementTools -Restart:$false -Verbose
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12' -Name ConfigurationState -Value 2
        Add-DhcpServerv4Scope -Name $scopeName -StartRange $start -EndRange $stop -SubnetMask $mask -LeaseDuration (New-TimeSpan -Days $day) -State Active
        Set-DhcpServerv4OptionValue -DnsServer $dns -DnsDomain $domain -Router $router
    } elseif ($choix -eq 2) {
        [string]$nomSrv = Read-Host "Veuillez saisir le nouveau nom de la machine"
        Rename-Computer -NewName $nomSrv -Restart
    } elseif ($choix -eq 3) {
        [SecureString]$password = Read-Host -AsSecureString "Veuillez entrer le mot de passe AD"
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart:$false -Verbose
        Install-ADDSForest `
            -DomainName 'isitech.local' `
            -DomainNetbiosName 'ISITECH' `
            -SafeModeAdministratorPassword $password `
            -InstallDns `
            -NoRebootOnCompletion:$false `
            -Force
    } else {
        Write-Host "Mauvais choix !"
    }
} while ($choix -ne 0)