import {getApps, initializeApp} from "firebase-admin/app";
import {FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions/v2";
import {CallableRequest, HttpsError} from "firebase-functions/v2/https";

// Bölge, tüm fonksiyonlar için burada bir kez ayarlanır.
// Flutter tarafındaki AppConfig.functionsRegion ile aynı olmalı.
// Her fonksiyon dosyası bu modülü en başta içe aktardığı için ayar önce çalışır.
setGlobalOptions({region: "europe-west1", maxInstances: 10});

if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
export {FieldValue, Timestamp};

/** events/{eventId} belgesinden fonksiyonların kullandığı alanlar. */
export interface EventDoc {
  ownerId: string;
  ownerName: string;
  title: string;
  status: "active" | "cancelled";
  startsAt: Timestamp;
  capacity: number;
  acceptedCount: number;
}

export type NotificationType =
  | "request_received"
  | "request_approved"
  | "request_rejected"
  | "event_cancelled";

/** Çağıran oturum açmış olmalı; uid döner. */
export function requireAuth(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "Devam etmek için giriş yapmalısın."
    );
  }
  return uid;
}

/** Çağrı verisinden güvenli bir metin alanı okur (belge kimliği olarak kullanılabilir). */
export function readId(data: unknown, key: string): string {
  if (typeof data !== "object" || data === null) {
    throw new HttpsError("invalid-argument", "Geçersiz istek.");
  }
  const value = (data as Record<string, unknown>)[key];
  if (
    typeof value !== "string" ||
    value.length === 0 ||
    value.length > 128 ||
    value.includes("/")
  ) {
    throw new HttpsError("invalid-argument", `Geçersiz alan: ${key}`);
  }
  return value;
}

export function notificationsCollection(uid: string) {
  return db.collection(`notifications/${uid}/items`);
}

/** Şema: docs/firestore_schema.md "notifications" bölümü. */
export function buildNotification(
  type: NotificationType,
  eventId: string,
  eventTitle: string
) {
  return {
    type,
    eventId,
    eventTitle,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  };
}
