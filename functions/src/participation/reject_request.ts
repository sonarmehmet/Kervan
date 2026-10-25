import {HttpsError, onCall} from "firebase-functions/v2/https";

import {
  EventDoc,
  buildNotification,
  db,
  notificationsCollection,
  readId,
  requireAuth,
} from "../common";

/** Bekleyen katılım talebini reddeder. Yalnızca etkinlik sahibi çağırabilir. */
export const rejectRequest = onCall(async (request) => {
  const ownerUid = requireAuth(request);
  const eventId = readId(request.data, "eventId");
  const userId = readId(request.data, "userId");

  await db.runTransaction(async (tx) => {
    const eventRef = db.doc(`events/${eventId}`);
    const requestRef = eventRef.collection("requests").doc(userId);
    const [eventSnap, requestSnap] = await tx.getAll(eventRef, requestRef);

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
    if (!requestSnap.exists) {
      throw new HttpsError("not-found", "Katılım talebi bulunamadı.");
    }
    if (requestSnap.get("status") !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "Bu talep artık beklemede değil."
      );
    }

    tx.update(requestRef, {status: "rejected"});
    tx.create(
      notificationsCollection(userId).doc(),
      buildNotification("request_rejected", eventId, event.title)
    );
  });

  return {ok: true};
});
