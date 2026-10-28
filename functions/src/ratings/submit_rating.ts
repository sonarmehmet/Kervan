import {HttpsError, onCall} from "firebase-functions/v2/https";

import {
  EventDoc,
  FieldValue,
  db,
  readId,
  requireAuth,
} from "../common";

const RATING_WINDOW_MS = 30 * 24 * 60 * 60 * 1000;

/**
 * Anonim, karşılıklı değerlendirme.
 *  - Katılımcı yalnızca etkinliği düzenleyeni, düzenleyen yalnızca onaylı katılımcıları puanlar.
 *  - Etkinlik başladıktan sonra ve en geç 30 gün içinde; her (etkinlik, puanlayan, hedef) için bir kez.
 *  - Yalnızca 1-5 yıldız; yorum yok. Hedef kişi puanı verenin kim olduğunu ASLA göremez:
 *    ham kayıtlar (`ratings`) yalnızca puanlayanın kendisi tarafından okunabilir,
 *    hedef yalnızca toplamları (`userStats`) görür.
 */
export const submitRating = onCall(async (request) => {
  const raterId = requireAuth(request);
  const eventId = readId(request.data, "eventId");
  const targetId = readId(request.data, "targetUserId");
  const stars = (request.data as Record<string, unknown>).stars;
  if (
    typeof stars !== "number" ||
    !Number.isInteger(stars) ||
    stars < 1 ||
    stars > 5
  ) {
    throw new HttpsError("invalid-argument", "Puan 1 ile 5 arasında olmalı.");
  }
  if (raterId === targetId) {
    throw new HttpsError("invalid-argument", "Kendini değerlendiremezsin.");
  }

  await db.runTransaction(async (tx) => {
    const eventRef = db.doc(`events/${eventId}`);
    const ratingRef = db.doc(`ratings/${eventId}_${raterId}_${targetId}`);
    const raterParticipantRef = eventRef.collection("participants").doc(raterId);
    const targetParticipantRef = eventRef.collection("participants").doc(targetId);
    const [eventSnap, ratingSnap, raterPart, targetPart] = await tx.getAll(
      eventRef,
      ratingRef,
      raterParticipantRef,
      targetParticipantRef
    );

    if (!eventSnap.exists) {
      throw new HttpsError("not-found", "Etkinlik bulunamadı.");
    }
    const event = eventSnap.data() as EventDoc;
    if (event.status !== "active") {
      throw new HttpsError(
        "failed-precondition",
        "İptal edilen etkinlik değerlendirilemez."
      );
    }
    const startsAt = event.startsAt.toMillis();
    if (startsAt > Date.now()) {
      throw new HttpsError(
        "failed-precondition",
        "Etkinlik başladıktan sonra değerlendirebilirsin."
      );
    }
    if (Date.now() - startsAt > RATING_WINDOW_MS) {
      throw new HttpsError(
        "failed-precondition",
        "Değerlendirme süresi (30 gün) doldu."
      );
    }

    // Rol: düzenleyen -> katılımcıyı, katılımcı -> düzenleyeni puanlar.
    let targetRole: "organizer" | "participant";
    if (raterId === event.ownerId) {
      if (!targetPart.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Yalnızca onaylı katılımcıları değerlendirebilirsin."
        );
      }
      targetRole = "participant";
    } else {
      if (!raterPart.exists || targetId !== event.ownerId) {
        throw new HttpsError(
          "permission-denied",
          "Yalnızca katıldığın etkinliğin düzenleyenini değerlendirebilirsin."
        );
      }
      targetRole = "organizer";
    }

    if (ratingSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Bu kişiyi bu etkinlik için zaten değerlendirdin."
      );
    }

    tx.create(ratingRef, {
      eventId,
      raterId,
      targetId,
      targetRole,
      stars,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(
      db.doc(`userStats/${targetId}`),
      targetRole === "organizer" ?
        {
          organizerSum: FieldValue.increment(stars),
          organizerCount: FieldValue.increment(1),
        } :
        {
          participantSum: FieldValue.increment(stars),
          participantCount: FieldValue.increment(1),
        },
      {merge: true}
    );
  });

  return {ok: true};
});
