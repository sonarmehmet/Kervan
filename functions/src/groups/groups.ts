import {HttpsError, onCall} from "firebase-functions/v2/https";

import {
  FieldValue,
  db,
  displayNameOf,
  readId,
  readText,
  requireAuth,
} from "../common";

const MAX_OWNED_GROUPS = 10;

/** Grup oluşturur; oluşturan otomatik üye (rol: owner) olur. */
export const createGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const name = readText(request.data, "name", 3, 50);
  const description = readText(request.data, "description", 0, 500);
  const category = readText(request.data, "category", 1, 30);
  const city = readText(request.data, "city", 2, 30);
  const ownerName = await displayNameOf(uid);

  const owned = await db
    .collection("groups")
    .where("ownerId", "==", uid)
    .where("status", "==", "active")
    .count()
    .get();
  if (owned.data().count >= MAX_OWNED_GROUPS) {
    throw new HttpsError(
      "failed-precondition",
      `En fazla ${MAX_OWNED_GROUPS} aktif grubun olabilir.`
    );
  }

  const groupRef = db.collection("groups").doc();
  const batch = db.batch();
  batch.create(groupRef, {
    name,
    description,
    category,
    city,
    ownerId: uid,
    ownerName,
    memberCount: 1,
    status: "active",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  batch.create(groupRef.collection("members").doc(uid), {
    userId: uid,
    userName: ownerName,
    role: "owner",
    joinedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  return {groupId: groupRef.id};
});

export const joinGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const groupId = readId(request.data, "groupId");
  const userName = await displayNameOf(uid);

  await db.runTransaction(async (tx) => {
    const groupRef = db.doc(`groups/${groupId}`);
    const memberRef = groupRef.collection("members").doc(uid);
    const [groupSnap, memberSnap] = await tx.getAll(groupRef, memberRef);
    if (!groupSnap.exists) {
      throw new HttpsError("not-found", "Grup bulunamadı.");
    }
    if (groupSnap.get("status") !== "active") {
      throw new HttpsError("failed-precondition", "Bu grup kapatılmış.");
    }
    if (memberSnap.exists) {
      throw new HttpsError("failed-precondition", "Zaten bu grubun üyesisin.");
    }
    tx.create(memberRef, {
      userId: uid,
      userName,
      role: "member",
      joinedAt: FieldValue.serverTimestamp(),
    });
    tx.update(groupRef, {memberCount: FieldValue.increment(1)});
  });
  return {ok: true};
});

/** Üyeyi gruptan çıkarır. Hesap silme de kullanır (`allowOwner`). */
export async function leaveGroupInternal(
  groupId: string,
  uid: string,
  allowOwner = false
): Promise<void> {
  await db.runTransaction(async (tx) => {
    const groupRef = db.doc(`groups/${groupId}`);
    const memberRef = groupRef.collection("members").doc(uid);
    const [groupSnap, memberSnap] = await tx.getAll(groupRef, memberRef);
    if (!memberSnap.exists) {
      throw new HttpsError("failed-precondition", "Bu grubun üyesi değilsin.");
    }
    if (groupSnap.exists && groupSnap.get("ownerId") === uid && !allowOwner) {
      throw new HttpsError(
        "failed-precondition",
        "Grup sahibi ayrılamaz; önce grubu kapat."
      );
    }
    tx.delete(memberRef);
    if (groupSnap.exists) {
      const count = Number(groupSnap.get("memberCount") ?? 0);
      tx.update(groupRef, {memberCount: Math.max(0, count - 1)});
    }
  });
}

export const leaveGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const groupId = readId(request.data, "groupId");
  await leaveGroupInternal(groupId, uid);
  return {ok: true};
});
