import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {db} from "../common";

/**
 * Bir etkinliğin kaydedilme sayısını (saveCount) sayarak yeniden yazar.
 * Sayım her seferinde baştan yapıldığı için tetikleyici tekrar çalışsa bile sonuç doğru kalır.
 */
export async function recountSaves(eventId: string): Promise<number> {
  const eventRef = db.doc(`events/${eventId}`);
  const snapshot = await db
    .collectionGroup("saved")
    .where("eventId", "==", eventId)
    .count()
    .get();
  const count = snapshot.data().count;
  const event = await eventRef.get();
  if (event.exists && event.get("saveCount") !== count) {
    await eventRef.update({saveCount: count});
  }
  return count;
}

/** users/{uid}/saved/{eventId} eklenince veya silinince etkinliğin saveCount alanını günceller. */
export const onSavedWritten = onDocumentWritten(
  "users/{uid}/saved/{eventId}",
  async (event) => {
    await recountSaves(event.params.eventId);
  }
);
