// Cloud Functions iş mantığı testleri. Firestore emulator üzerinde çalışır:
//   firebase emulators:exec --only firestore --project demo-rota "node --test functions/test"
// Önce `npm run build` (functions/lib üretilir) gerekir.
process.env.GCLOUD_PROJECT = "demo-rota";

const test = require("node:test");
const assert = require("node:assert/strict");

const {db, Timestamp} = require("../lib/common");
const {approveRequest} = require("../lib/participation/approve_request");
const {rejectRequest} = require("../lib/participation/reject_request");
const {leaveEvent} = require("../lib/participation/leave_event");
const {cancelEvent} = require("../lib/participation/cancel_event");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error("FIRESTORE_EMULATOR_HOST yok; testler emulator ile çalıştırılmalı.");
}

const call = (fn, uid, data) => fn.run({auth: uid ? {uid} : undefined, data});

let counter = 0;
async function seedEvent({capacity = 2, requests = 0, startsInMs = 3600_000} = {}) {
  const eventId = `e${Date.now()}_${counter++}`;
  await db.doc(`events/${eventId}`).set({
    ownerId: "owner",
    ownerName: "Sahip",
    title: "Test etkinliği",
    status: "active",
    startsAt: Timestamp.fromMillis(Date.now() + startsInMs),
    capacity,
    acceptedCount: 0,
  });
  for (let i = 0; i < requests; i++) {
    await db.doc(`events/${eventId}/requests/u${i}`).set({
      userId: `u${i}`,
      userName: `Kullanıcı ${i}`,
      status: "pending",
    });
  }
  return eventId;
}

const eventData = async (id) => (await db.doc(`events/${id}`).get()).data();
const count = async (path) => (await db.collection(path).get()).size;
const code = async (promise) => {
  try {
    await promise;
  } catch (e) {
    return e.code;
  }
  return "ok";
};

test("eşzamanlı onaylar kapasiteyi aşmaz", async () => {
  const id = await seedEvent({capacity: 2, requests: 6});
  const results = await Promise.all(
    [0, 1, 2, 3, 4, 5].map((i) =>
      code(call(approveRequest, "owner", {eventId: id, userId: `u${i}`}))
    )
  );
  assert.equal(results.filter((r) => r === "ok").length, 2);
  assert.equal(results.filter((r) => r === "failed-precondition").length, 4);
  assert.equal((await eventData(id)).acceptedCount, 2);
  assert.equal(await count(`events/${id}/participants`), 2);
});

test("aynı talebi iki kez onaylamak sayacı iki kez artırmaz", async () => {
  const id = await seedEvent({capacity: 5, requests: 1});
  const results = await Promise.all([
    code(call(approveRequest, "owner", {eventId: id, userId: "u0"})),
    code(call(approveRequest, "owner", {eventId: id, userId: "u0"})),
  ]);
  assert.equal(results.filter((r) => r === "ok").length, 1);
  assert.equal((await eventData(id)).acceptedCount, 1);
});

test("onay: giriş yapmamış ve sahip olmayan reddedilir", async () => {
  const id = await seedEvent({requests: 1});
  assert.equal(await code(call(approveRequest, null, {eventId: id, userId: "u0"})), "unauthenticated");
  assert.equal(await code(call(approveRequest, "baskasi", {eventId: id, userId: "u0"})), "permission-denied");
  assert.equal((await eventData(id)).acceptedCount, 0);
});

test("onay: geçersiz kimlik ve geçmiş tarihli etkinlik reddedilir", async () => {
  const id = await seedEvent({requests: 1});
  assert.equal(await code(call(approveRequest, "owner", {eventId: "a/b", userId: "u0"})), "invalid-argument");
  const past = await seedEvent({requests: 1, startsInMs: -1000});
  assert.equal(await code(call(approveRequest, "owner", {eventId: past, userId: "u0"})), "failed-precondition");
  assert.equal(await code(call(approveRequest, "owner", {eventId: id, userId: "yok"})), "not-found");
});

test("onay bildirim ve katılımcı kaydı oluşturur", async () => {
  const id = await seedEvent({requests: 1});
  await call(approveRequest, "owner", {eventId: id, userId: "u0"});
  const req = (await db.doc(`events/${id}/requests/u0`).get()).data();
  assert.equal(req.status, "approved");
  assert.ok((await db.doc(`events/${id}/participants/u0`).get()).exists);
  const notes = await db.collection("notifications/u0/items").where("eventId", "==", id).get();
  assert.equal(notes.size, 1);
  assert.equal(notes.docs[0].get("type"), "request_approved");
});

test("red: yalnızca sahip ve yalnızca bekleyen talep", async () => {
  const id = await seedEvent({requests: 1});
  assert.equal(await code(call(rejectRequest, "baskasi", {eventId: id, userId: "u0"})), "permission-denied");
  assert.equal(await code(call(rejectRequest, "owner", {eventId: id, userId: "u0"})), "ok");
  assert.equal(await code(call(rejectRequest, "owner", {eventId: id, userId: "u0"})), "failed-precondition");
  assert.equal(await code(call(approveRequest, "owner", {eventId: id, userId: "u0"})), "failed-precondition");
});

test("ayrılma sayacı azaltır, katılımcı değilse hata verir", async () => {
  const id = await seedEvent({capacity: 3, requests: 2});
  await call(approveRequest, "owner", {eventId: id, userId: "u0"});
  await call(approveRequest, "owner", {eventId: id, userId: "u1"});
  assert.equal(await code(call(leaveEvent, "yabanci", {eventId: id})), "failed-precondition");
  assert.equal(await code(call(leaveEvent, "u0", {eventId: id})), "ok");
  assert.equal((await eventData(id)).acceptedCount, 1);
  assert.equal(await count(`events/${id}/participants`), 1);
  assert.equal((await db.doc(`events/${id}/requests/u0`).get()).get("status"), "cancelled");
});

test("iptal: yalnızca sahip, durum cancelled olur, ikinci iptal hata verir", async () => {
  const id = await seedEvent({capacity: 3, requests: 2});
  await call(approveRequest, "owner", {eventId: id, userId: "u0"});
  assert.equal(await code(call(cancelEvent, "baskasi", {eventId: id})), "permission-denied");
  assert.equal(await code(call(cancelEvent, "owner", {eventId: id})), "ok");
  assert.equal((await eventData(id)).status, "cancelled");
  assert.equal(await code(call(cancelEvent, "owner", {eventId: id})), "failed-precondition");
  assert.equal(await code(call(approveRequest, "owner", {eventId: id, userId: "u1"})), "failed-precondition");
  const notes = await db.collection("notifications/u0/items").where("eventId", "==", id).get();
  assert.ok(notes.docs.some((d) => d.get("type") === "event_cancelled"));
});
