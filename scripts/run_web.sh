#!/usr/bin/env bash
# Rota - Chrome'da test (Flutter web).
# Önce Firebase konsolu > Proje ayarları > "Web uygulaması ekle" ile bir web uygulaması oluştur,
# çıkan ayarları web_firebase.env dosyasına yaz (örnek: scripts/web_firebase.env.example).
# Kullanım:  bash scripts/run_web.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ENV_FILE="${WEB_ENV_FILE:-web_firebase.env}"
[ -f "$ENV_FILE" ] || { echo "HATA: $ENV_FILE yok. scripts/web_firebase.env.example dosyasını kopyalayıp doldur."; exit 1; }
set -a; . "./$ENV_FILE"; set +a
for v in FIREBASE_API_KEY FIREBASE_APP_ID FIREBASE_MESSAGING_SENDER_ID FIREBASE_PROJECT_ID FIREBASE_AUTH_DOMAIN; do
  [ -n "${!v:-}" ] || { echo "HATA: $ENV_FILE içinde $v boş."; exit 1; }
done
[ -d web ] || flutter create . --project-name rota --platforms web && { git checkout -- lib pubspec.yaml test 2>/dev/null || true; rm -f test/widget_test.dart; }
flutter pub get
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
  --dart-define=FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET:-}" \
  --dart-define=SHARE_BASE_URL="${SHARE_BASE_URL:-}"
