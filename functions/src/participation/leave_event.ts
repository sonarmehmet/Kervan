import {HttpsError, onCall} from "firebase-functions/v2/https";

import {FieldValue, db, readId, requireAuth} from "../common";

/**
 * Onaylı katılımcıyı etkinlikten çıkarır, sayacı azaltır ve talebi `cancelled` yapar.
 * Hem `leaveEvent` hem de hesap silme tarafından kullanılır.
 */
export async function leaveEventInternal(
  eventId: string,
  userId: string
): Promise<void> {
  await db.runTransaction(async (tx) => {
    const eventRef = db.doc(`events/${eventId}`);
    const participantRef = eventRef.collection("participants").doc(userId);
    const requestRef = eventRef.collection("requests").doc(userId);

    const [eventSnap, participantSnap, requestSnap] = await tx.getAll(
      eventRef,
      participantRef,
      requestRef
    );

    if (!participantSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Bu etkinliğin katılımcısı değilsin."
      );
    }

    tx.delete(participantRef);
    if (eventSnap.exists) {
      const current = Number(eventSnap.get("acceptedCount") ?? 0);
      tx.update(eventRef, {acceptedCount: Math.max(0, current - 1)});
    }
    if (requestSnap.exists) {
      tx.update(requestRef, {
        status: "cancelled",
        leftAt: FieldValue.serverTimestamp(),
      });
    }
  });
}

export const leaveEvent = onCall(async (request) => {
  const uid = requireAuth(request);
  const eventId = readId(request.data, "eventId");
  await leaveEventInternal(eventId, uid);
  return {ok: true};
});
