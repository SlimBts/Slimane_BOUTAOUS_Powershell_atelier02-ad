$root = 'D:\Partages'
$departments = 'RH', 'IT', 'Direction'

# Création de la racine
New-Item -Path $root -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# Création des sous dossiers par département
foreach ($dept in $departement) {
    $path = Join-Path $root $dept

    # New-Item avec -Force crée le dossier seulement s'il n'existe pas, sans erreur
    $item = New-Item -Path $path -ItemType Directory -Force -ErrorAction SilentlyContinue

    if ($item) {
        write-Host "Créé : $path" -ForegroundColor Green
    }
}

# Vérification
Get-ChildItem -Path $root -Directory | Select-Object Name, FullName

foreach ($dept in $departement) {
    $shareName = "$dept`$"
    # $ final = partage masqué (non visible en navigation)
    $path = Join-Path $root $dept

    # Suppression idempotente du partage existant
    if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
        Remove-SmbShare -Name $shareName -Force
    }

    New-SmbShare `
        -Name $shareName `
        -Path $path `
        -FullAccess "LAB\GRP-$dept" `
        -Description "Partage du service $dept"
}

# Lister les partages masqués crées
Get-SmbShare | Where-Object Name -like '*$' | Select-Object Name, path, ScopeName