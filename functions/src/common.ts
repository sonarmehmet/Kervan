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
  | "event_cancelled"
  | "waitlist_spot_open"
  | "event_reminder_24h"
  | "event_reminder_1h"
  | "new_followed_event"
  | "new_group_event";

/** Çağıran oturum açmış olmalı; uid döner. */
export function requireAuth(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "Devam etmek için giriş yapmalısın."
    );
  }
  if (request.auth?.token?.email_verified !== true) {
    throw new HttpsError(
      "permission-denied",
      "Devam etmek için e-posta adresini doğrulamalısın."
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
  eventTitle: string,
  extra: {actorName?: string; groupName?: string} = {}
) {
  return {
    type,
    eventId,
    eventTitle,
    ...(extra.actorName ? {actorName: extra.actorName} : {}),
    ...(extra.groupName ? {groupName: extra.groupName} : {}),
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  };
}

/** Kullanıcının görünen adı (profil yoksa yedek ad). */
export async function displayNameOf(uid: string): Promise<string> {
  const snap = await db.doc(`users/${uid}`).get();
  const name = snap.get("displayName");
  return typeof name === "string" && name.length > 0 ? name : "Katılımcı";
}

/** Çağrı verisinden sınırlı uzunlukta metin okur. */
export function readText(
  data: unknown,
  key: string,
  min: number,
  max: number
): string {
  const value =
    typeof data === "object" && data !== null ?
      (data as Record<string, unknown>)[key] :
      undefined;
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `Geçersiz alan: ${key}`);
  }
  const text = value.trim();
  if (text.length < min || text.length > max) {
    throw new HttpsError(
      "invalid-argument",
      `${key} ${min}-${max} karakter olmalı.`
    );
  }
  return text;
}
