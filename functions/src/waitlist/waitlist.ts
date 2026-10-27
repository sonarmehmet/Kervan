import {HttpsError, onCall} from "firebase-functions/v2/https";

import {
  EventDoc,
  FieldValue,
  buildNotification,
  db,
  displayNameOf,
  notificationsCollection,
  readId,
  requireAuth,
} from "../common";

/**
 * Dolu etkinlikte bekleme listesine yazılır. Yer açılınca (bkz. notifyWaitlist) sıradaki
 * kişilere bildirim gider; kişi normal katılma isteği gönderir.
 */
export const joinWaitlist = onCall(async (request) => {
  const uid = requireAuth(request);
  const eventId = readId(request.data, "eventId");
  const userName = await displayNameOf(uid);

  await db.runTransaction(async (tx) => {
    const eventRef = db.doc(`events/${eventId}`);
    const waitRef = eventRef.collection("waitlist").doc(uid);
    const requestRef = eventRef.collection("requests").doc(uid);
    const participantRef = eventRef.collection("participants").doc(uid);
    const [eventSnap, waitSnap, requestSnap, participantSnap] = await tx.getAll(
      eventRef,
      waitRef,
      requestRef,
      participantRef
    );

    if (!eventSnap.exists) {
      throw new HttpsError("not-found", "Etkinlik bulunamadı.");
    }
    const event = eventSnap.data() as EventDoc;
    if (event.ownerId === uid) {
      throw new HttpsError(
        "failed-precondition",
        "Kendi etkinliğinin bekleme listesine yazılamazsın."
      );
    }
    if (event.status !== "active" || event.startsAt.toMillis() <= Date.now()) {
      throw new HttpsError(
        "failed-precondition",
        "Bu etkinlik artık katılıma açık değil."
      );
    }
    if (event.acceptedCount < event.capacity) {
      throw new HttpsError(
        "failed-precondition",
        "Etkinlikte yer var; doğrudan katılma isteği gönderebilirsin."
      );
    }
    if (participantSnap.exists) {
      throw new HttpsError("failed-precondition", "Zaten katılımcısın.");
    }
    const requestStatus = requestSnap.get("status");
    if (requestStatus === "pending" || requestStatus === "approved") {
      throw new HttpsError(
        "failed-precondition",
        "Bu etkinlik için zaten bir talebin var."
      );
    }
    if (requestStatus === "rejected") {
      throw new HttpsError(
        "failed-precondition",
        "Bu etkinlik için talebin reddedilmişti."
      );
    }
    if (waitSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Zaten bekleme listesindesin."
      );
    }
    tx.create(waitRef, {
      userId: uid,
      userName,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return {ok: true};
});

export const leaveWaitlist = onCall(async (request) => {
  const uid = requireAuth(request);
  const eventId = readId(request.data, "eventId");
  await db.doc(`events/${eventId}/waitlist/${uid}`).delete();
  return {ok: true};
});

/**
 * Boş yer kadar (en eski sıradan başlayarak) bekleyene "yer açıldı" bildirimi gönderir ve
 * onları listeden çıkarır; kişiler normal katılma isteği gönderir.
 * Etkinlikte katılımcı sayısı azaldığında veya kapasite arttığında tetiklenir.
 */
export async function notifyWaitlist(eventId: string): Promise<number> {
  const eventRef = db.doc(`events/${eventId}`);
  return db.runTransaction(async (tx) => {
    const eventSnap = await tx.get(eventRef);
    if (!eventSnap.exists) return 0;
    const event = eventSnap.data() as EventDoc;
    if (event.status !== "active" || event.startsAt.toMillis() <= Date.now()) {
      return 0;
    }
    const spots = event.capacity - event.acceptedCount;
    if (spots <= 0) return 0;

    const waiting = await tx.get(
      eventRef.collection("waitlist").orderBy("createdAt").limit(spots)
    );
    for (const doc of waiting.docs) {
      tx.create(
        notificationsCollection(doc.id).doc(),
        buildNotification("waitlist_spot_open", eventId, event.title)
      );
      tx.delete(doc.ref);
    }
    return waiting.size;
  });
}
