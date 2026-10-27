import {onDocumentCreated} from "firebase-functions/v2/firestore";

import {
  EventDoc,
  NotificationType,
  buildNotification,
  db,
  notificationsCollection,
} from "../common";

const MAX_RECIPIENTS = 500;

interface Recipient {
  type: NotificationType;
  extra: {actorName?: string; groupName?: string};
}

/**
 * Yeni etkinlik için bildirim alacaklar: düzenleyeni takip edenler ve (etkinlik bir gruba aitse)
 * grup üyeleri. Aynı kişi ikisindeyse yalnızca grup bildirimi gider. Düzenleyeni engelleyenler
 * hariç tutulur. Tekrarlayan seride yalnızca ilk etkinlik için bildirim gider.
 */
export async function notifyEventAudience(eventId: string): Promise<number> {
  const eventSnap = await db.doc(`events/${eventId}`).get();
  if (!eventSnap.exists) return 0;
  const event = eventSnap.data() as EventDoc & {
    groupId?: string;
    seriesId?: string;
    seriesIndex?: number;
  };
  if (event.status !== "active") return 0;
  if (event.seriesId && (event.seriesIndex ?? 0) !== 0) return 0;

  const recipients = new Map<string, Recipient>();

  if (event.groupId) {
    const groupSnap = await db.doc(`groups/${event.groupId}`).get();
    const groupName = String(groupSnap.get("name") ?? "Grup");
    const members = await db
      .collection(`groups/${event.groupId}/members`)
      .limit(MAX_RECIPIENTS)
      .get();
    for (const doc of members.docs) {
      recipients.set(doc.id, {type: "new_group_event", extra: {groupName}});
    }
  }

  const followers = await db
    .collectionGroup("following")
    .where("organizerId", "==", event.ownerId)
    .limit(MAX_RECIPIENTS)
    .get();
  for (const doc of followers.docs) {
    const followerId = doc.ref.parent.parent?.id;
    if (followerId && !recipients.has(followerId)) {
      recipients.set(followerId, {
        type: "new_followed_event",
        extra: {actorName: event.ownerName},
      });
    }
  }

  recipients.delete(event.ownerId);
  const ids = [...recipients.keys()];
  if (ids.length === 0) return 0;

  // Düzenleyeni engelleyenlere bildirim gitmez.
  const blockRefs = ids.map((id) =>
    db.doc(`users/${id}/blocks/${event.ownerId}`)
  );
  const blockSnaps = await db.getAll(...blockRefs);
  const writer = db.bulkWriter();
  let sent = 0;
  ids.forEach((id, index) => {
    if (blockSnaps[index].exists) return;
    const recipient = recipients.get(id) as Recipient;
    writer.create(
      notificationsCollection(id).doc(),
      buildNotification(recipient.type, eventId, event.title, recipient.extra)
    );
    sent++;
  });
  await writer.close();
  return sent;
}

export const onEventCreated = onDocumentCreated(
  "events/{eventId}",
  async (event) => {
    await notifyEventAudience(event.params.eventId);
  }
);
