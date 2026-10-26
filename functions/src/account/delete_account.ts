import {getAuth} from "firebase-admin/auth";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {db, requireAuth} from "../common";
import {cancelEventInternal} from "../participation/cancel_event";
import {leaveEventInternal} from "../participation/leave_event";

/** Beklenen "zaten yapılmış / artık geçersiz" hatalarını yutar, gerçek hataları fırlatır. */
async function ignorePrecondition(action: () => Promise<void>): Promise<void> {
  try {
    await action();
  } catch (error) {
    if (error instanceof HttpsError && error.code === "failed-precondition") {
      return;
    }
    throw error;
  }
}

/**
 * Hesabı ve ilişkili verileri siler.
 *  1. Sahibi olduğu etkinlikler iptal edilir, sahip adı anonimleştirilir, tam konum silinir.
 *  2. Katılımcı olduğu etkinliklerden çıkarılır (sayaç düzeltilir).
 *  3. Sohbet mesajları ve gönderdiği tüm katılım talepleri silinir.
 *  4. Profil, engeller ve bildirimler silinir.
 *  5. Auth kaydı en sonda silinir; böylece bir adım başarısız olursa kullanıcı tekrar deneyebilir.
 * Şikâyet kayıtları moderasyon için saklanır.
 */
export const deleteAccount = onCall({timeoutSeconds: 120}, async (request) => {
  const uid = requireAuth(request);

  // 1. Sahibi olduğu etkinlikler
  const ownedEvents = await db
    .collection("events")
    .where("ownerId", "==", uid)
    .get();
  for (const doc of ownedEvents.docs) {
    if (doc.get("status") === "active") {
      await ignorePrecondition(() => cancelEventInternal(doc.id, uid));
    }
    await doc.ref.update({ownerName: "Silinmiş kullanıcı"});
    await doc.ref.collection("private").doc("location").delete();
  }

  // 2. Katılımcı olduğu etkinlikler
  const participations = await db
    .collectionGroup("participants")
    .where("userId", "==", uid)
    .get();
  for (const doc of participations.docs) {
    const eventRef = doc.ref.parent.parent;
    if (eventRef) {
      await ignorePrecondition(() => leaveEventInternal(eventRef.id, uid));
    }
  }

  // 2b. Sohbette yazdığı mesajlar
  const messages = await db
    .collectionGroup("messages")
    .where("senderId", "==", uid)
    .get();
  const messageWriter = db.bulkWriter();
  for (const doc of messages.docs) {
    messageWriter.delete(doc.ref);
  }
  await messageWriter.close();

  // 3. Gönderdiği talepler
  const requests = await db
    .collectionGroup("requests")
    .where("userId", "==", uid)
    .get();
  const writer = db.bulkWriter();
  for (const doc of requests.docs) {
    writer.delete(doc.ref);
  }
  await writer.close();

  // 4. Profil, engeller, bildirimler
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await db.recursiveDelete(db.doc(`notifications/${uid}`));

  // 5. Auth kaydı
  await getAuth().deleteUser(uid);

  return {ok: true};
});
