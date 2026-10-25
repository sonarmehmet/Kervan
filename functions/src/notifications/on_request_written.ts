import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {
  EventDoc,
  buildNotification,
  db,
  notificationsCollection,
} from "../common";

/**
 * Bir katılım talebi `pending` durumuna geçtiğinde (yeni talep veya geri çekilen talebin
 * yeniden açılması) etkinlik sahibine `request_received` bildirimi üretir.
 */
export const onRequestWritten = onDocumentWritten(
  "events/{eventId}/requests/{userId}",
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return;

    const before = event.data?.before;
    const beforeStatus = before?.exists ? before.get("status") : undefined;
    if (after.get("status") !== "pending" || beforeStatus === "pending") return;

    const {eventId} = event.params;
    const eventSnap = await db.doc(`events/${eventId}`).get();
    if (!eventSnap.exists) return;

    const eventData = eventSnap.data() as EventDoc;
    await notificationsCollection(eventData.ownerId).add(
      buildNotification("request_received", eventId, eventData.title)
    );
  }
);
