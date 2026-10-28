import {HttpsError, onCall} from "firebase-functions/v2/https";

import {
  EventDoc,
  FieldValue,
  buildNotification,
  db,
  notificationsCollection,
  readId,
  requireAuth,
} from "../common";

/**
 * Etkinliği iptal eder (yalnızca sahibi). Katılımcılara ve bekleyen talep sahiplerine
 * `event_cancelled` bildirimi gider, bekleyen talepler `cancelled` olur.
 * Hem `cancelEvent` hem de hesap silme tarafından kullanılır.
 */
export async function cancelEventInternal(
  eventId: string,
  ownerUid: string
): Promise<void> {
  const eventRef = db.doc(`events/${eventId}`);

  const title = await db.runTransaction(async (tx) => {
    const snap = await tx.get(eventRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Etkinlik bulunamadı.");
    }
    const event = snap.data() as EventDoc;
    if (event.ownerId !== ownerUid) {
      throw new HttpsError(
        "permission-denied",
        "Bu etkinliği iptal etme yetkin yok."
      );
    }
    if (event.status !== "active") {
      throw new HttpsError(
        "failed-precondition",
        "Etkinlik zaten iptal edilmiş."
      );
    }
    tx.update(eventRef, {
      status: "cancelled",
      updatedAt: FieldValue.serverTimestamp(),
    });
    return event.title;
  });

  const [participants, pendingRequests] = await Promise.all([
    eventRef.collection("participants").get(),
    eventRef.collection("requests").where("status", "==", "pending").get(),
  ]);

  const targets = new Set<string>();
  participants.docs.forEach((doc) => targets.add(doc.id));
  pendingRequests.docs.forEach((doc) => targets.add(doc.id));
  targets.delete(ownerUid);

  const writer = db.bulkWriter();
  for (const userId of targets) {
    writer.create(
      notificationsCollection(userId).doc(),
      buildNotification("event_cancelled", eventId, title)
    );
  }
  for (const doc of pendingRequests.docs) {
    writer.update(doc.ref, {status: "cancelled"});
  }
  await writer.close();
}

export const cancelEvent = onCall(async (request) => {
  const uid = requireAuth(request);
  const eventId = readId(request.data, "eventId");
  await cancelEventInternal(eventId, uid);
  return {ok: true};
});
