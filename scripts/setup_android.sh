#!/usr/bin/env bash
# Rota - Android klasörünü hazırlar (bir kez çalıştır).
# Kullanım:  bash scripts/setup_android.sh com.senin.rota
#   $1 = organizasyon (applicationId = <org>.rota). Play'e çıktıktan sonra DEĞİŞTİRİLEMEZ.
# Yaptıkları:
#   1. flutter create ile android/ klasörünü oluşturur (lib/, pubspec.yaml'a dokunmaz)
#   2. minSdk'yı 23 yapar (Firebase şartı)
#   3. AndroidManifest'e bildirim izni (POST_NOTIFICATIONS) ekler
#   4. Uygulama adını "Rota" yapar
#   5. android/app/google-services.json VARSA Google Services eklentisini bağlar
#      (dosya yoksa bu adımı atlar; dosyayı koyduktan sonra betiği tekrar çalıştır)
set -euo pipefail

ORG="${1:-com.rota}"

if [ ! -d android ]; then
  flutter create . --project-name rota --org "$ORG" --platforms android
  git checkout -- lib pubspec.yaml test 2>/dev/null || true
  rm -f test/widget_test.dart
fi

GRADLE_APP=""
for f in android/app/build.gradle.kts android/app/build.gradle; do
  [ -f "$f" ] && GRADLE_APP="$f"
done
[ -n "$GRADLE_APP" ] || { echo "android/app/build.gradle(.kts) bulunamadı"; exit 1; }

# 2. minSdk
sed -i -E 's/minSdk(Version)?( =|) +flutter\.minSdkVersion/minSdk\1\2 23/' "$GRADLE_APP"
grep -nE 'minSdk' "$GRADLE_APP" || true

# 3. Bildirim izni
MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q POST_NOTIFICATIONS "$MANIFEST"; then
  sed -i '0,/<manifest[^>]*>/s//&\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"\/>/' "$MANIFEST"
fi

# 4. Uygulama adı
sed -i -E 's/android:label="[^"]*"/android:label="Rota"/' "$MANIFEST"

# 5. Google Services eklentisi
if [ -f android/app/google-services.json ]; then
  SETTINGS=""
  for f in android/settings.gradle.kts android/settings.gradle; do
    [ -f "$f" ] && SETTINGS="$f"
  done
  if [ -n "$SETTINGS" ] && ! grep -q "com.google.gms.google-services" "$SETTINGS"; then
    if [[ "$SETTINGS" == *.kts ]]; then
      sed -i '0,/id("org.jetbrains.kotlin.android")/s//&\n    id("com.google.gms.google-services") version "4.4.2" apply false/' "$SETTINGS"
    else
      sed -i "0,/id \"org.jetbrains.kotlin.android\"/s//&\n    id \"com.google.gms.google-services\" version \"4.4.2\" apply false/" "$SETTINGS"
    fi
  fi
  if ! grep -q "com.google.gms.google-services" "$GRADLE_APP"; then
    if [[ "$GRADLE_APP" == *.kts ]]; then
      sed -i '0,/id("dev.flutter.flutter-gradle-plugin")/s//&\n    id("com.google.gms.google-services")/' "$GRADLE_APP"
    else
      sed -i "0,/id \"dev.flutter.flutter-gradle-plugin\"/s//&\n    id \"com.google.gms.google-services\"/" "$GRADLE_APP"
    fi
  fi
  echo "Google Services eklentisi bağlandı."
else
  echo "UYARI: android/app/google-services.json yok; Firebase bağlanana kadar uygulama açılışta hata ekranı gösterir."
fi
echo "Android hazır."
