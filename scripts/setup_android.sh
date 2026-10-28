#!/usr/bin/env bash
# Rota - Android klasörünü hazırlar (bir kez çalıştır).
# Kullanım:  bash scripts/setup_android.sh com.senin.rota
#   $1 = organizasyon (applicationId = <org>.rota). Play'e çıktıktan sonra DEĞİŞTİRİLEMEZ.
# Yaptıkları:
#   1. flutter create ile android/ klasörünü oluşturur (lib/, pubspec.yaml'a dokunmaz)
#   2. minSdk'yı 23 yapar (Firebase şartı)
#   3. AndroidManifest'e bildirim izni (POST_NOTIFICATIONS) ekler
#   4. Uygulama adını "Rota" yapar
#   4b. SHARE_HOST ortam değişkeni verilirse (örn. SHARE_HOST=rota-app.web.app) paylaşım bağlantıları
#       (https://HOST/events/ID) için Android uygulama bağlantısı (intent-filter) ekler
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

# 4b. Paylaşım bağlantısı (App Links)
if [ -n "${SHARE_HOST:-}" ] && ! grep -q "android:host=\"$SHARE_HOST\"" "$MANIFEST"; then
  FILTER="            <intent-filter android:autoVerify=\"true\">\n                <action android:name=\"android.intent.action.VIEW\"/>\n                <category android:name=\"android.intent.category.DEFAULT\"/>\n                <category android:name=\"android.intent.category.BROWSABLE\"/>\n                <data android:scheme=\"https\" android:host=\"$SHARE_HOST\" android:pathPrefix=\"/events\"/>\n            </intent-filter>"
  sed -i "0,/<\/activity>/s##$FILTER\n        </activity>#" "$MANIFEST"
  grep -q 'flutter_deeplinking_enabled' "$MANIFEST" || \
    sed -i '0,/<\/activity>/s##    <meta-data android:name="flutter_deeplinking_enabled" android:value="true"/>\n        </activity>#' "$MANIFEST"
  echo "Paylaşım bağlantısı eklendi: https://$SHARE_HOST/events/..."
fi

# 5. Google Services eklentisi
if [ -f android/app/google-services.json ]; then
  SETTINGS=""
  for f in android/settings.gradle.kts android/settings.gradle; do
    [ -f "$f" ] && SETTINGS="$f"
  done
  if [ -n "$SETTINGS" ] && ! grep -q "com.google.gms.google-services" "$SETTINGS"; then
    if [[ "$SETTINGS" == *.kts ]]; then
      sed -i '0,/id("org.jetbrains.kotlin.android")/s//id("com.google.gms.google-services") version "4.4.2" apply false\n    &/' "$SETTINGS"
    else
      sed -i "0,/id \"org.jetbrains.kotlin.android\"/s//id \"com.google.gms.google-services\" version \"4.4.2\" apply false\n    &/" "$SETTINGS"
    fi
  fi
  if ! grep -q "com.google.gms.google-services" "$GRADLE_APP"; then
    if [[ "$GRADLE_APP" == *.kts ]]; then
      sed -i '0,/id("dev.flutter.flutter-gradle-plugin")/s//id("com.google.gms.google-services")\n    &/' "$GRADLE_APP"
    else
      sed -i "0,/id \"dev.flutter.flutter-gradle-plugin\"/s//id \"com.google.gms.google-services\"\n    &/" "$GRADLE_APP"
    fi
  fi
  echo "Google Services eklentisi bağlandı."
else
  echo "UYARI: android/app/google-services.json yok; Firebase bağlanana kadar uygulama açılışta hata ekranı gösterir."
fi
echo "Android hazır."
