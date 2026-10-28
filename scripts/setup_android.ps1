# Rota - Android klasörünü hazırlar (Windows PowerShell). scripts/setup_android.sh'nin karşılığıdır.
# Kullanım (proje klasöründe):
#   powershell -ExecutionPolicy Bypass -File scripts\setup_android.ps1 -Org com.vefa
#   -Org: applicationId = <Org>.rota  (Play'e çıktıktan sonra DEĞİŞTİRİLEMEZ)
#   -ShareHost: (isteğe bağlı) paylaşım bağlantıları için alan adı, örn. rota-test.web.app
# Betik tekrar çalıştırılabilir. android\app\google-services.json'u koyduktan sonra bir kez daha çalıştır.
param(
  [string]$Org = 'com.rota',
  [string]$ShareHost = ''
)
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$utf8 = New-Object System.Text.UTF8Encoding($false)
function Read-Text([string]$path) { [IO.File]::ReadAllText((Resolve-Path $path).Path) }
function Write-Text([string]$path, [string]$text) { [IO.File]::WriteAllText((Resolve-Path $path).Path, $text, $utf8) }

# 1. android/ klasörü
if (-not (Test-Path 'android')) {
  flutter create . --project-name rota --org $Org --platforms android
  if ($LASTEXITCODE -ne 0) { throw 'flutter create basarisiz oldu.' }
  Remove-Item 'test\widget_test.dart' -ErrorAction SilentlyContinue
}

$gradleApp = $null
foreach ($f in 'android\app\build.gradle.kts', 'android\app\build.gradle') {
  if (Test-Path $f) { $gradleApp = $f }
}
if (-not $gradleApp) { throw 'android\app\build.gradle(.kts) bulunamadi.' }

# 2. minSdk = 23 (Firebase sarti)
$t = Read-Text $gradleApp
$t = [regex]::Replace($t, 'minSdk(Version)?(\s*=\s*|\s+)flutter\.minSdkVersion',
  [System.Text.RegularExpressions.MatchEvaluator] { param($m) 'minSdk' + $m.Groups[1].Value + $m.Groups[2].Value + '23' })
Write-Text $gradleApp $t
Select-String -Path $gradleApp -Pattern 'minSdk' | ForEach-Object { $_.Line.Trim() }

# 3. Bildirim izni + 4. uygulama adi
$manifest = 'android\app\src\main\AndroidManifest.xml'
$m = Read-Text $manifest
if ($m -notmatch 'POST_NOTIFICATIONS') {
  $m = ([regex]'<manifest[^>]*>').Replace($m,
    [System.Text.RegularExpressions.MatchEvaluator] { param($x) $x.Value + "`n    <uses-permission android:name=`"android.permission.POST_NOTIFICATIONS`"/>" }, 1)
}
$m = $m -replace 'android:label="[^"]*"', 'android:label="Rota"'

# 4b. Paylasim baglantisi (App Links)
if ($ShareHost -ne '' -and $m -notmatch [regex]::Escape("android:host=`"$ShareHost`"")) {
  $filter = "            <intent-filter android:autoVerify=`"true`">`n" +
    "                <action android:name=`"android.intent.action.VIEW`"/>`n" +
    "                <category android:name=`"android.intent.category.DEFAULT`"/>`n" +
    "                <category android:name=`"android.intent.category.BROWSABLE`"/>`n" +
    "                <data android:scheme=`"https`" android:host=`"$ShareHost`" android:pathPrefix=`"/events`"/>`n" +
    "            </intent-filter>`n"
  $idx = $m.IndexOf('</activity>')
  if ($idx -ge 0) {
    $meta = ''
    if ($m -notmatch 'flutter_deeplinking_enabled') {
      $meta = "            <meta-data android:name=`"flutter_deeplinking_enabled`" android:value=`"true`"/>`n"
    }
    $m = $m.Insert($idx, $filter + $meta + '        ')
    Write-Host "Paylasim baglantisi eklendi: https://$ShareHost/events/..."
  }
}
Write-Text $manifest $m

# 5. Google Services eklentisi
if (Test-Path 'android\app\google-services.json') {
  $settings = $null
  foreach ($f in 'android\settings.gradle.kts', 'android\settings.gradle') {
    if (Test-Path $f) { $settings = $f }
  }
  if ($settings) {
    $s = Read-Text $settings
    if ($s -notmatch 'com\.google\.gms\.google-services') {
      if ($settings.EndsWith('.kts')) {
        $s = $s -replace '(?m)^(\s*)id\("org\.jetbrains\.kotlin\.android"\)', ('$1id("com.google.gms.google-services") version "4.4.2" apply false' + "`n" + '$1id("org.jetbrains.kotlin.android")')
      } else {
        $s = $s -replace '(?m)^(\s*)id "org\.jetbrains\.kotlin\.android"', ('$1id "com.google.gms.google-services" version "4.4.2" apply false' + "`n" + '$1id "org.jetbrains.kotlin.android"')
      }
      Write-Text $settings $s
    }
  }
  $g = Read-Text $gradleApp
  if ($g -notmatch 'com\.google\.gms\.google-services') {
    if ($gradleApp.EndsWith('.kts')) {
      $g = $g -replace '(?m)^(\s*)id\("dev\.flutter\.flutter-gradle-plugin"\)', ('$1id("com.google.gms.google-services")' + "`n" + '$1id("dev.flutter.flutter-gradle-plugin")')
    } else {
      $g = $g -replace '(?m)^(\s*)id "dev\.flutter\.flutter-gradle-plugin"', ('$1id "com.google.gms.google-services"' + "`n" + '$1id "dev.flutter.flutter-gradle-plugin"')
    }
    Write-Text $gradleApp $g
  }
  Write-Host 'Google Services eklentisi baglandi.'
} else {
  Write-Host 'UYARI: android\app\google-services.json yok; dosyayi koyduktan sonra bu betigi tekrar calistir.'
}
Write-Host 'Android hazir.'
