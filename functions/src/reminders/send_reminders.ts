import {onSchedule} from "firebase-functions/v2/scheduler";

import {
  EventDoc,
  Timestamp,
  buildNotification,
  db,
  notificationsCollection,
} from "../common";

const HOUR = 60 * 60 * 1000;

/**
 * Başlamasına 24 saat (veya 1 saat) kalan aktif etkinliklerin sahibine ve onaylı katılımcılarına
 * hatırlatma bildirimi üretir. Her etkinlik için her hatırlatma EN FAZLA BİR KEZ gönderilir
 * (bayrak ve bildirimler aynı transaction'da yazılır). 24 saatten az kala oluşturulan etkinlik
 * için yalnızca 1 saatlik hatırlatma gider.
 * Dönüş: gönderilen bildirim sayısı.
 */
export async function processReminders(nowMs = Date.now()): Promise<number> {
  const snap = await db
    .collection("events")
    .where("status", "==", "active")
    .where("startsAt", ">", Timestamp.fromMillis(nowMs))
    .where("startsAt", "<=", Timestamp.fromMillis(nowMs + 24 * HOUR))
    .get();

  let sent = 0;
  for (const doc of snap.docs) {
    sent += await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (!fresh.exists) return 0;
      const event = fresh.data() as EventDoc & {
        reminder24hSent?: boolean;
        reminder1hSent?: boolean;
      };
      if (event.status !== "active") return 0;

      const remaining = event.startsAt.toMillis() - nowMs;
      let kind: "event_reminder_1h" | "event_reminder_24h" | null = null;
      if (remaining <= HOUR && !event.reminder1hSent) {
        kind = "event_reminder_1h";
      } else if (remaining > HOUR && !event.reminder24hSent) {
        kind = "event_reminder_24h";
      }
      if (!kind) return 0;

      const participants = await tx.get(doc.ref.collection("participants"));
      const targets = new Set<string>([event.ownerId]);
      participants.docs.forEach((p) => targets.add(p.id));

      for (const uid of targets) {
        tx.create(
          notificationsCollection(uid).doc(),
          buildNotification(kind, doc.id, event.title)
        );
      }
      tx.update(
        doc.ref,
        kind === "event_reminder_1h" ?
          {reminder1hSent: true, reminder24hSent: true} :
          {reminder24hSent: true}
      );
      return targets.size;
    });
  }
  return sent;
}

/** 15 dakikada bir çalışır (Cloud Scheduler gerekir; Blaze plan). */
export const sendEventReminders = onSchedule(
  {schedule: "every 15 minutes", timeZone: "Europe/Istanbul"},
  async () => {
    await processReminders();
  }
);
