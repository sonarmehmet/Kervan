import {getMessaging} from "firebase-admin/messaging";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

import {NotificationType, db} from "../common";

/** Bildirim türüne göre push başlığı ve metni (Türkçe). */
export function pushText(
  type: NotificationType | string,
  eventTitle: string,
  extra: {actorName?: string; groupName?: string} = {}
): {title: string; body: string} {
  switch (type) {
  case "request_received":
    return {
      title: "Yeni katılım talebi",
      body: `"${eventTitle}" etkinliğine yeni bir katılım talebi geldi.`,
    };
  case "request_approved":
    return {
      title: "Talebin onaylandı",
      body: `"${eventTitle}" etkinliğine katılımın onaylandı.`,
    };
  case "request_rejected":
    return {
      title: "Talebin reddedildi",
      body: `"${eventTitle}" etkinliğine katılım talebin reddedildi.`,
    };
  case "event_cancelled":
    return {
      title: "Etkinlik iptal edildi",
      body: `"${eventTitle}" etkinliği iptal edildi.`,
    };
  case "waitlist_spot_open":
    return {
      title: "Yer açıldı!",
      body: `"${eventTitle}" etkinliğinde yer açıldı. Hemen katılma isteği gönder.`,
    };
  case "event_reminder_24h":
    return {
      title: "Etkinlik yarın",
      body: `"${eventTitle}" etkinliği 24 saat içinde başlıyor.`,
    };
  case "event_reminder_1h":
    return {
      title: "Etkinlik yaklaşıyor",
      body: `"${eventTitle}" etkinliği 1 saat içinde başlıyor.`,
    };
  case "new_followed_event":
    return {
      title: "Takip ettiğin kişi etkinlik oluşturdu",
      body: `${extra.actorName ?? "Bir düzenleyici"}: "${eventTitle}"`,
    };
  case "new_group_event":
    return {
      title: `${extra.groupName ?? "Grubun"} için yeni etkinlik`,
      body: `"${eventTitle}" etkinliği oluşturuldu.`,
    };
  default:
    return {
      title: "Rota",
      body: `"${eventTitle}" etkinliğiyle ilgili bir güncelleme var.`,
    };
  }
}

const INVALID_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

/**
 * Yeni bir bildirim belgesi oluşunca kullanıcının tüm cihazlarına push gönderir.
 * Geçersiz hale gelmiş jetonları temizler. Push başarısız olsa bile uygulama içi
 * bildirim zaten kayıtlıdır; bu yüzden hatalar yutulup loglanır (tekrar deneme yok).
 */
export const onNotificationCreated = onDocumentCreated(
  "notifications/{uid}/items/{itemId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const {uid} = event.params;
    const notification = snapshot.data();
    const tokensSnapshot = await db
      .collection(`users/${uid}/fcmTokens`)
      .get();
    const tokens = tokensSnapshot.docs.map((doc) => doc.id);
    if (tokens.length === 0) return;

    const {title, body} = pushText(
      String(notification.type ?? ""),
      String(notification.eventTitle ?? ""),
      {
        actorName: String(notification.actorName ?? ""),
        groupName: String(notification.groupName ?? ""),
      }
    );

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {title, body},
      data: {
        type: String(notification.type ?? ""),
        eventId: String(notification.eventId ?? ""),
      },
      android: {priority: "high"},
    });

    const invalidTokens: string[] = [];
    response.responses.forEach((result, index) => {
      if (!result.success && INVALID_TOKEN_CODES.has(result.error?.code ?? "")) {
        invalidTokens.push(tokens[index]);
      }
    });
    await Promise.all(
      invalidTokens.map((token) =>
        db.doc(`users/${uid}/fcmTokens/${token}`).delete()
      )
    );
  }
);
