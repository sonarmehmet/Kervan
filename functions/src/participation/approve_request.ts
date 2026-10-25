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
 * Katılım talebini onaylar.
 * Kapasite kontrolü ve sayaç artışı TEK transaction içinde yapılır; böylece iki talep
 * aynı anda onaylansa bile kapasite aşılamaz.
 */
export const approveRequest = onCall(async (request) => {
  const ownerUid = requireAuth(request);
  const eventId = readId(request.data, "eventId");
  const userId = readId(request.data, "userId");

  await db.runTransaction(async (tx) => {
    const eventRef = db.doc(`events/${eventId}`);
    const requestRef = eventRef.collection("requests").doc(userId);
    const participantRef = eventRef.collection("participants").doc(userId);

    const [eventSnap, requestSnap, participantSnap] = await tx.getAll(
      eventRef,
      requestRef,
      participantRef
    );

    if (!eventSnap.exists) {
      throw new HttpsError("not-found", "Etkinlik bulunamadı.");
    }
    const event = eventSnap.data() as EventDoc;

    if (event.ownerId !== ownerUid) {
      throw new HttpsError(
        "permission-denied",
        "Bu etkinliğin talepleri üzerinde işlem yapamazsın."
      );
    }
    if (event.status !== "active") {
      throw new HttpsError("failed-precondition", "Etkinlik iptal edilmiş.");
    }
    if (event.startsAt.toMillis() <= Date.now()) {
      throw new HttpsError(
        "failed-precondition",
        "Etkinliğin tarihi geçmiş."
      );
    }
    if (!requestSnap.exists) {
      throw new HttpsError("not-found", "Katılım talebi bulunamadı.");
    }
    if (requestSnap.get("status") !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "Bu talep artık beklemede değil."
      );
    }
    if (participantSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Bu kişi zaten katılımcı."
      );
    }
    if (event.acceptedCount >= event.capacity) {
      throw new HttpsError("failed-precondition", "Etkinlik kapasitesi dolu.");
    }

    const userName = String(requestSnap.get("userName") ?? "Katılımcı");

    tx.set(participantRef, {
      userId,
      userName,
      joinedAt: FieldValue.serverTimestamp(),
    });
    tx.update(eventRef, {acceptedCount: FieldValue.increment(1)});
    tx.update(requestRef, {status: "approved"});
    tx.create(
      notificationsCollection(userId).doc(),
      buildNotification("request_approved", eventId, event.title)
    );
  });

  return {ok: true};
});
