param(
  [switch]$DryRun,
  [switch]$AdminOnly
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$firebaseOptionsPath = Join-Path $repoRoot 'lib\firebase_options.dart'
$testUsersPath = Join-Path $repoRoot 'test-users.local.json'
$testGymId = 'local-test-gym'
$testGymCode = 'QGYM26'
$testGymName = 'QUANTUM TEST CENTER'
$testGymAddress = 'Entorno local de pruebas'
$testGymPhone = '+525512345678'

function Read-TextFile {
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    throw "No se encontró el archivo: $Path"
  }

  return Get-Content -Path $Path -Raw
}

function Get-FirebaseWebConfig {
  $content = Read-TextFile -Path $firebaseOptionsPath
  $webBlock = [regex]::Match(
    $content,
    "static const FirebaseOptions web = FirebaseOptions\((?s:(.*?))\);"
  )

  if (-not $webBlock.Success) {
    throw 'No se pudo resolver la configuración web de Firebase desde lib/firebase_options.dart'
  }

  $apiKeyMatch = [regex]::Match($webBlock.Groups[1].Value, "apiKey:\s*'([^']+)'")
  $projectIdMatch = [regex]::Match($webBlock.Groups[1].Value, "projectId:\s*'([^']+)'")

  if (-not $apiKeyMatch.Success -or -not $projectIdMatch.Success) {
    throw 'No se pudo resolver apiKey/projectId desde lib/firebase_options.dart'
  }

  return [pscustomobject]@{
    ApiKey = $apiKeyMatch.Groups[1].Value
    ProjectId = $projectIdMatch.Groups[1].Value
  }
}

function Read-TestUsers {
  $raw = Read-TextFile -Path $testUsersPath
  $data = $raw | ConvertFrom-Json

  if (-not $data.users) {
    throw 'test-users.local.json no contiene la propiedad users'
  }

  $result = @{}
  foreach ($user in $data.users) {
    $result[$user.key] = $user
  }

  foreach ($required in @('admin')) {
    if (-not $result.ContainsKey($required)) {
      throw "Falta el usuario requerido '$required' en test-users.local.json"
    }
  }

  if (-not $AdminOnly) {
    foreach ($required in @('owner', 'staff', 'client')) {
      if (-not $result.ContainsKey($required)) {
        throw "Falta el usuario requerido '$required' en test-users.local.json"
      }
    }
  }

  return $result
}

function Split-PersonName {
  param([string]$FullName)

  $normalized = if ($null -eq $FullName) { '' } else { [string]$FullName }
  $normalized = $normalized.Trim()
  if ([string]::IsNullOrWhiteSpace($normalized)) {
    return [pscustomobject]@{ FirstName = ''; LastName = '' }
  }

  $parts = $normalized -split '\s+', 2
  if ($parts.Count -eq 1) {
    return [pscustomobject]@{ FirstName = $parts[0]; LastName = '' }
  }

  return [pscustomobject]@{ FirstName = $parts[0]; LastName = $parts[1] }
}

function Convert-ToFirestoreFields {
  param($Value)

  $fields = @{}
  foreach ($property in $Value.PSObject.Properties) {
    $entryValue = $property.Value
    if ($null -eq $entryValue) {
      continue
    }

    if ($entryValue -is [bool]) {
      $fields[$property.Name] = @{ booleanValue = $entryValue }
      continue
    }

    if ($entryValue -is [int] -or $entryValue -is [long]) {
      $fields[$property.Name] = @{ integerValue = "$entryValue" }
      continue
    }

    if ($entryValue -is [double] -or $entryValue -is [decimal] -or $entryValue -is [float]) {
      $fields[$property.Name] = @{ doubleValue = [double]$entryValue }
      continue
    }

    $fields[$property.Name] = @{ stringValue = [string]$entryValue }
  }

  return $fields
}

function Get-ResponseBody {
  param($Exception)

  if ($null -eq $Exception.Response) {
    return $Exception.Message
  }

  $stream = $Exception.Response.GetResponseStream()
  if ($null -eq $stream) {
    return $Exception.Message
  }

  $reader = New-Object System.IO.StreamReader($stream)
  $body = $reader.ReadToEnd()
  $reader.Dispose()
  $stream.Dispose()

  if ([string]::IsNullOrWhiteSpace($body)) {
    return $Exception.Message
  }

  return $body
}

function Invoke-FirebaseJson {
  param(
    [string]$Method,
    [string]$Uri,
    $Body,
    [hashtable]$Headers = @{}
  )

  if ($DryRun) {
    Write-Host "[DRY RUN] $Method $Uri"
    return $null
  }

  try {
    $jsonBody = if ($null -eq $Body) { $null } else { $Body | ConvertTo-Json -Depth 30 }
    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers -ContentType 'application/json' -Body $jsonBody
  }
  catch {
    $detail = Get-ResponseBody -Exception $_.Exception
    throw "Firebase request failed: $detail"
  }
}

function Ensure-FirebaseUser {
  param(
    [pscustomobject]$User,
    [string]$ApiKey
  )

  $signUpUri = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$ApiKey"
  $signInUri = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$ApiKey"
  $updateUri = "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$ApiKey"
  $fullName = $User.name

  if ($DryRun) {
    return [pscustomobject]@{
      Key = $User.key
      Email = $User.email
      LocalId = "dryrun-$($User.key)"
      IdToken = "dryrun-token-$($User.key)"
    }
  }

  $authPayload = @{
    email = $User.email
    password = $User.password
    returnSecureToken = $true
  }

  try {
    $authResponse = Invoke-FirebaseJson -Method 'POST' -Uri $signUpUri -Body $authPayload
  }
  catch {
    if ($_.Exception.Message -notmatch 'EMAIL_EXISTS') {
      throw
    }

    $authResponse = Invoke-FirebaseJson -Method 'POST' -Uri $signInUri -Body $authPayload
  }

  $updatePayload = @{
    idToken = $authResponse.idToken
    displayName = $fullName
    returnSecureToken = $true
  }

  $updateResponse = Invoke-FirebaseJson -Method 'POST' -Uri $updateUri -Body $updatePayload

  return [pscustomobject]@{
    Key = $User.key
    Email = $User.email
    LocalId = $updateResponse.localId
    IdToken = $updateResponse.idToken
  }
}

function Set-FirestoreDocument {
  param(
    [string]$ProjectId,
    [string]$DocumentPath,
    [pscustomobject]$DocumentData,
    [string]$IdToken
  )

  $uri = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents/$DocumentPath"
  $headers = @{ Authorization = "Bearer $IdToken" }
  $body = @{ fields = Convert-ToFirestoreFields -Value $DocumentData }

  Invoke-FirebaseJson -Method 'PATCH' -Uri $uri -Headers $headers -Body $body | Out-Null
}

function Get-RoleCollectionName {
  param([string]$Role)

  switch ($Role) {
    'owner' { return 'owners' }
    'employee' { return 'employees' }
    'client' { return 'clients' }
    default { throw "Rol no soportado para colección anidada: $Role" }
  }
}

function New-UserProfileDocument {
  param(
    [pscustomobject]$User,
    [string]$Uid,
    [string]$Role,
    [string]$GymId,
    [string]$CreatedAt
  )

  $name = Split-PersonName -FullName $User.name

  return [pscustomobject]@{
    email = $User.email
    firstName = $name.FirstName
    lastName = $name.LastName
    role = $Role
    gymId = $GymId
    createdAt = $CreatedAt
    isActive = $true
    membershipStatus = 'approved'
  }
}

function New-GymDocument {
  param([string]$CreatedAt)

  return [pscustomobject]@{
    code = $testGymCode
    name = $testGymName
    address = $testGymAddress
    phone = $testGymPhone
    createdAt = $CreatedAt
    isActive = $true
  }
}

$config = Get-FirebaseWebConfig
$testUsers = Read-TestUsers
$createdAt = [DateTime]::UtcNow.ToString('o')

Write-Host 'Preparando usuarios test en Firebase...'

$adminSession = Ensure-FirebaseUser -User $testUsers['admin'] -ApiKey $config.ApiKey
$adminDocument = New-UserProfileDocument -User $testUsers['admin'] -Uid $adminSession.LocalId -Role 'admin' -GymId 'admin-global' -CreatedAt $createdAt
Set-FirestoreDocument -ProjectId $config.ProjectId -DocumentPath "users/$($adminSession.LocalId)" -DocumentData $adminDocument -IdToken $adminSession.IdToken

$seededUsers = @()
$seededUsers += [pscustomobject]@{ key = 'admin'; email = $testUsers['admin'].email; uid = $adminSession.LocalId; role = 'admin'; gymId = 'admin-global' }

if (-not $AdminOnly) {
  $gymDocument = New-GymDocument -CreatedAt $createdAt
  Set-FirestoreDocument -ProjectId $config.ProjectId -DocumentPath "gyms/$testGymId" -DocumentData $gymDocument -IdToken $adminSession.IdToken

  foreach ($key in @('owner', 'staff', 'client')) {
    $user = $testUsers[$key]
    $session = Ensure-FirebaseUser -User $user -ApiKey $config.ApiKey
    $role = [string]$user.role
    $collectionName = Get-RoleCollectionName -Role $role
    $profileDocument = New-UserProfileDocument -User $user -Uid $session.LocalId -Role $role -GymId $testGymId -CreatedAt $createdAt

    Set-FirestoreDocument -ProjectId $config.ProjectId -DocumentPath "users/$($session.LocalId)" -DocumentData $profileDocument -IdToken $adminSession.IdToken
    Set-FirestoreDocument -ProjectId $config.ProjectId -DocumentPath "gyms/$testGymId/$collectionName/$($session.LocalId)" -DocumentData $profileDocument -IdToken $adminSession.IdToken

    $seededUsers += [pscustomobject]@{ key = $key; email = $user.email; uid = $session.LocalId; role = $role; gymId = $testGymId }
  }
}

Write-Host ''
Write-Host 'Seed completado.'
if ($AdminOnly) {
  Write-Host 'Modo admin personal: solo se aseguró la cuenta admin permanente.'
} else {
  Write-Host "Gym de prueba: $testGymName"
  Write-Host "Gym ID: $testGymId"
  Write-Host "Gym Code: $testGymCode"
}
Write-Host ''
$seededUsers | Format-Table -AutoSize
