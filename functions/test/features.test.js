// Bekleme listesi, anonim değerlendirme, gruplar, hatırlatma ve bildirim kitlesi testleri.
// Çalıştırma: firebase emulators:exec --only firestore --project demo-rota "node --test functions/test"
process.env.GCLOUD_PROJECT = "demo-rota";

const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");

const {db, Timestamp} = require("../lib/common");
const {joinWaitlist, leaveWaitlist, notifyWaitlist} = require("../lib/waitlist/waitlist");
const {submitRating} = require("../lib/ratings/submit_rating");
const {createGroup, joinGroup, leaveGroup} = require("../lib/groups/groups");
const {processReminders} = require("../lib/reminders/send_reminders");
const {notifyEventAudience} = require("../lib/events/on_event_created");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error("FIRESTORE_EMULATOR_HOST yok; testler emulator ile çalıştırılmalı.");
}

const call = (fn, uid, data, verified = true) =>
  fn.run({auth: uid ? {uid, token: {email_verified: verified}} : undefined, data});
const code = async (promise) => {
  try {
    await promise;
  } catch (e) {
    return e.code;
  }
  return "ok";
};
const rid = () => crypto.randomBytes(4).toString("hex");
const HOUR = 3600_000;

async function seedEvent({
  owner,
  capacity = 5,
  accepted = 0,
  startsInMs = 2 * HOUR,
  status = "active",
  extra = {},
  participants = [],
}) {
  const id = `e_${rid()}`;
  await db.doc(`events/${id}`).set({
    ownerId: owner,
    ownerName: "Sahip",
    title: "Test etkinliği",
    status,
    startsAt: Timestamp.fromMillis(Date.now() + startsInMs),
    capacity,
    acceptedCount: accepted || participants.length,
    ...extra,
  });
  for (const uid of participants) {
    await db.doc(`events/${id}/participants/${uid}`).set({userId: uid, userName: uid});
  }
  return id;
}
const notesOf = async (uid, eventId) =>
  (await db.collection(`notifications/${uid}/items`).where("eventId", "==", eventId).get())
    .docs.map((d) => d.data());

// ---------- Bekleme listesi ----------

test("bekleme listesi: yer varken katılınamaz, doluyken katılınır, tekrar ve katılımcı engellenir", async () => {
  const [owner, a, b] = [`o_${rid()}`, `a_${rid()}`, `b_${rid()}`];
  const roomy = await seedEvent({owner, capacity: 3, accepted: 1});
  assert.equal(await code(call(joinWaitlist, a, {eventId: roomy})), "failed-precondition");

  const full = await seedEvent({owner, capacity: 1, participants: [b]});
  assert.equal(await code(call(joinWaitlist, a, {eventId: full})), "ok");
  assert.equal(await code(call(joinWaitlist, a, {eventId: full})), "failed-precondition");
  assert.equal(await code(call(joinWaitlist, b, {eventId: full})), "failed-precondition");
  assert.equal(await code(call(joinWaitlist, owner, {eventId: full})), "failed-precondition");
  assert.equal(await code(call(joinWaitlist, null, {eventId: full})), "unauthenticated");

  assert.equal(await code(call(leaveWaitlist, a, {eventId: full})), "ok");
  assert.equal((await db.doc(`events/${full}/waitlist/${a}`).get()).exists, false);
});

test("bekleme listesi: bekleyen talebi olan veya reddedilen kişi yazılamaz", async () => {
  const [owner, p, r] = [`o_${rid()}`, `p_${rid()}`, `r_${rid()}`];
  const id = await seedEvent({owner, capacity: 1, accepted: 1});
  await db.doc(`events/${id}/requests/${p}`).set({userId: p, userName: "p", status: "pending"});
  await db.doc(`events/${id}/requests/${r}`).set({userId: r, userName: "r", status: "rejected"});
  assert.equal(await code(call(joinWaitlist, p, {eventId: id})), "failed-precondition");
  assert.equal(await code(call(joinWaitlist, r, {eventId: id})), "failed-precondition");
});

test("yer açılınca en eski bekleyenlere (boş yer kadar) bildirim gider ve listeden çıkarılırlar", async () => {
  const owner = `o_${rid()}`;
  const [w1, w2, w3] = [`w1_${rid()}`, `w2_${rid()}`, `w3_${rid()}`];
  const id = await seedEvent({owner, capacity: 2, accepted: 2});
  const base = Date.now();
  for (const [i, uid] of [w1, w2, w3].entries()) {
    await db.doc(`events/${id}/waitlist/${uid}`).set({
      userId: uid, userName: uid, createdAt: Timestamp.fromMillis(base + i * 1000),
    });
  }
  assert.equal(await notifyWaitlist(id), 0); // yer yok

  await db.doc(`events/${id}`).update({acceptedCount: 1});
  assert.equal(await notifyWaitlist(id), 1);
  assert.equal((await notesOf(w1, id))[0].type, "waitlist_spot_open");
  assert.equal((await notesOf(w2, id)).length, 0);
  assert.equal((await db.doc(`events/${id}/waitlist/${w1}`).get()).exists, false);
  assert.equal((await db.doc(`events/${id}/waitlist/${w2}`).get()).exists, true);
});

test("iptal edilmiş etkinlikte bekleme listesi bildirmez", async () => {
  const owner = `o_${rid()}`;
  const w = `w_${rid()}`;
  const id = await seedEvent({owner, capacity: 2, accepted: 0, status: "cancelled"});
  await db.doc(`events/${id}/waitlist/${w}`).set({userId: w, userName: w, createdAt: Timestamp.now()});
  assert.equal(await notifyWaitlist(id), 0);
  assert.equal((await notesOf(w, id)).length, 0);
});

// ---------- Anonim değerlendirme ----------

test("değerlendirme: katılımcı düzenleyeni, düzenleyen katılımcıyı puanlar; toplamlar güncellenir", async () => {
  const [owner, p1, p2] = [`o_${rid()}`, `p1_${rid()}`, `p2_${rid()}`];
  const id = await seedEvent({owner, startsInMs: -2 * HOUR, participants: [p1, p2]});

  assert.equal(await code(call(submitRating, p1, {eventId: id, targetUserId: owner, stars: 5})), "ok");
  assert.equal(await code(call(submitRating, p2, {eventId: id, targetUserId: owner, stars: 3})), "ok");
  const ownerStats = (await db.doc(`userStats/${owner}`).get()).data();
  assert.equal(ownerStats.organizerSum, 8);
  assert.equal(ownerStats.organizerCount, 2);

  assert.equal(await code(call(submitRating, owner, {eventId: id, targetUserId: p1, stars: 4})), "ok");
  const p1Stats = (await db.doc(`userStats/${p1}`).get()).data();
  assert.equal(p1Stats.participantSum, 4);
  assert.equal(p1Stats.participantCount, 1);
});

test("değerlendirme: tekrar, kendini, yabancıyı, katılımcılar arası ve geçersiz puanı reddeder", async () => {
  const [owner, p1, p2, stranger] = [`o_${rid()}`, `p1_${rid()}`, `p2_${rid()}`, `s_${rid()}`];
  const id = await seedEvent({owner, startsInMs: -HOUR, participants: [p1, p2]});

  assert.equal(await code(call(submitRating, p1, {eventId: id, targetUserId: owner, stars: 5})), "ok");
  assert.equal(await code(call(submitRating, p1, {eventId: id, targetUserId: owner, stars: 1})), "failed-precondition");
  assert.equal(await code(call(submitRating, p1, {eventId: id, targetUserId: p1, stars: 5})), "invalid-argument");
  assert.equal(await code(call(submitRating, p1, {eventId: id, targetUserId: owner, stars: 6})), "invalid-argument");
  assert.equal(await code(call(submitRating, p1, {eventId: id, targetUserId: owner, stars: 2.5})), "invalid-argument");
  assert.equal(await code(call(submitRating, p1, {eventId: id, targetUserId: p2, stars: 5})), "permission-denied");
  assert.equal(await code(call(submitRating, stranger, {eventId: id, targetUserId: owner, stars: 5})), "permission-denied");
  assert.equal(await code(call(submitRating, owner, {eventId: id, targetUserId: stranger, stars: 5})), "failed-precondition");
  assert.equal((await db.doc(`userStats/${owner}`).get()).data().organizerCount, 1);
});

test("değerlendirme: etkinlik başlamadan, iptalde ve 30 gün sonra yapılamaz", async () => {
  const [owner, p] = [`o_${rid()}`, `p_${rid()}`];
  const future = await seedEvent({owner, startsInMs: HOUR, participants: [p]});
  const cancelled = await seedEvent({owner, startsInMs: -HOUR, status: "cancelled", participants: [p]});
  const old = await seedEvent({owner, startsInMs: -31 * 24 * HOUR, participants: [p]});
  for (const id of [future, cancelled, old]) {
    assert.equal(await code(call(submitRating, p, {eventId: id, targetUserId: owner, stars: 5})), "failed-precondition", id);
  }
});

test("değerlendirme kaydı puanlayanı içerir ama istatistik belgesi içermez", async () => {
  const [owner, p] = [`o_${rid()}`, `p_${rid()}`];
  const id = await seedEvent({owner, startsInMs: -HOUR, participants: [p]});
  await call(submitRating, p, {eventId: id, targetUserId: owner, stars: 4});
  const stats = JSON.stringify((await db.doc(`userStats/${owner}`).get()).data());
  assert.ok(!stats.includes(p), "istatistikte puanlayanın kimliği olmamalı");
  const raw = (await db.doc(`ratings/${id}_${p}_${owner}`).get()).data();
  assert.equal(raw.raterId, p);
  assert.equal(raw.stars, 4);
});

// ---------- Gruplar ----------

test("grup: oluşturma, katılma, ayrılma ve üye sayısı", async () => {
  const [owner, m1, m2] = [`o_${rid()}`, `m1_${rid()}`, `m2_${rid()}`];
  const {groupId} = await call(createGroup, owner, {
    name: "Elazığ Koşu Grubu", description: "Haftalık koşu", category: "running", city: "Elazığ",
  });
  let group = (await db.doc(`groups/${groupId}`).get()).data();
  assert.equal(group.memberCount, 1);
  assert.equal(group.status, "active");
  assert.equal((await db.doc(`groups/${groupId}/members/${owner}`).get()).get("role"), "owner");

  assert.equal(await code(call(joinGroup, m1, {groupId})), "ok");
  assert.equal(await code(call(joinGroup, m2, {groupId})), "ok");
  assert.equal(await code(call(joinGroup, m1, {groupId})), "failed-precondition");
  assert.equal((await db.doc(`groups/${groupId}`).get()).get("memberCount"), 3);

  assert.equal(await code(call(leaveGroup, m1, {groupId})), "ok");
  assert.equal(await code(call(leaveGroup, m1, {groupId})), "failed-precondition");
  assert.equal(await code(call(leaveGroup, owner, {groupId})), "failed-precondition");
  assert.equal((await db.doc(`groups/${groupId}`).get()).get("memberCount"), 2);
});

test("grup: geçersiz alan reddedilir, kapalı gruba katılınamaz, eşzamanlı katılım sayıyı bozmaz", async () => {
  const owner = `o_${rid()}`;
  assert.equal(await code(call(createGroup, owner, {name: "ab", description: "", category: "x", city: "Elazığ"})), "invalid-argument");
  assert.equal(await code(call(createGroup, null, {name: "Geçerli ad", description: "", category: "x", city: "Elazığ"})), "unauthenticated");

  const {groupId} = await call(createGroup, owner, {name: "Kamp Grubu", description: "", category: "camping", city: "Elazığ"});
  const users = Array.from({length: 8}, () => `u_${rid()}`);
  const results = await Promise.all(users.map((u) => code(call(joinGroup, u, {groupId}))));
  assert.ok(results.every((r) => r === "ok"));
  assert.equal((await db.doc(`groups/${groupId}`).get()).get("memberCount"), 9);

  await db.doc(`groups/${groupId}`).update({status: "closed"});
  assert.equal(await code(call(joinGroup, `late_${rid()}`, {groupId})), "failed-precondition");
});

// ---------- Hatırlatmalar ----------

test("hatırlatma: 24 saat ve 1 saat kala bir kez gönderilir", async () => {
  const [owner, p1, p2] = [`o_${rid()}`, `p1_${rid()}`, `p2_${rid()}`];
  const id = await seedEvent({owner, startsInMs: 23 * HOUR, participants: [p1, p2]});

  await processReminders();
  for (const uid of [owner, p1, p2]) {
    const notes = await notesOf(uid, id);
    assert.equal(notes.length, 1, uid);
    assert.equal(notes[0].type, "event_reminder_24h");
  }
  await processReminders(); // aynı pencerede tekrar gönderilmez
  assert.equal((await notesOf(p1, id)).length, 1);

  await processReminders(Date.now() + 22.5 * HOUR); // ~30 dk kaldı
  const notes = await notesOf(p1, id);
  assert.equal(notes.length, 2);
  assert.ok(notes.some((n) => n.type === "event_reminder_1h"));
  await processReminders(Date.now() + 22.6 * HOUR);
  assert.equal((await notesOf(p1, id)).length, 2);
});

test("hatırlatma: 24 saatten uzak, iptal edilmiş ve geçmiş etkinliklere gönderilmez; kısa süreli olana yalnızca 1 saatlik gider", async () => {
  const owner = `o_${rid()}`;
  const far = await seedEvent({owner, startsInMs: 30 * HOUR});
  const cancelled = await seedEvent({owner, startsInMs: 5 * HOUR, status: "cancelled"});
  const past = await seedEvent({owner, startsInMs: -HOUR});
  const soon = await seedEvent({owner, startsInMs: 30 * 60 * 1000});
  await processReminders();
  assert.equal((await notesOf(owner, far)).length, 0);
  assert.equal((await notesOf(owner, cancelled)).length, 0);
  assert.equal((await notesOf(owner, past)).length, 0);
  const soonNotes = await notesOf(owner, soon);
  assert.equal(soonNotes.length, 1);
  assert.equal(soonNotes[0].type, "event_reminder_1h");
});

// ---------- Yeni etkinlik bildirim kitlesi ----------

test("yeni etkinlik: takipçilere gider, düzenleyeni engelleyen hariç", async () => {
  const [owner, f1, f2] = [`o_${rid()}`, `f1_${rid()}`, `f2_${rid()}`];
  for (const f of [f1, f2]) {
    await db.doc(`users/${f}/following/${owner}`).set({organizerId: owner, organizerName: "Sahip"});
  }
  await db.doc(`users/${f2}/blocks/${owner}`).set({blockedAt: Timestamp.now()});
  const id = await seedEvent({owner});
  await notifyEventAudience(id);
  const n1 = await notesOf(f1, id);
  assert.equal(n1.length, 1);
  assert.equal(n1[0].type, "new_followed_event");
  assert.equal(n1[0].actorName, "Sahip");
  assert.equal((await notesOf(f2, id)).length, 0);
  assert.equal((await notesOf(owner, id)).length, 0);
});

test("yeni grup etkinliği: üyelere gider; hem üye hem takipçi olana yalnızca grup bildirimi", async () => {
  const [owner, both, memberOnly, followerOnly] = [`o_${rid()}`, `b_${rid()}`, `m_${rid()}`, `f_${rid()}`];
  const {groupId} = await call(createGroup, owner, {name: "Satranç Kulübü", description: "", category: "chess", city: "Elazığ"});
  await call(joinGroup, both, {groupId});
  await call(joinGroup, memberOnly, {groupId});
  for (const f of [both, followerOnly]) {
    await db.doc(`users/${f}/following/${owner}`).set({organizerId: owner, organizerName: "Sahip"});
  }
  const id = await seedEvent({owner, extra: {groupId, groupName: "Satranç Kulübü"}});
  await notifyEventAudience(id);

  assert.equal((await notesOf(both, id)).length, 1);
  assert.equal((await notesOf(both, id))[0].type, "new_group_event");
  assert.equal((await notesOf(memberOnly, id))[0].type, "new_group_event");
  assert.equal((await notesOf(memberOnly, id))[0].groupName, "Satranç Kulübü");
  assert.equal((await notesOf(followerOnly, id))[0].type, "new_followed_event");
});

test("seride yalnızca ilk etkinlik için bildirim gider", async () => {
  const [owner, f] = [`o_${rid()}`, `f_${rid()}`];
  await db.doc(`users/${f}/following/${owner}`).set({organizerId: owner, organizerName: "Sahip"});
  const first = await seedEvent({owner, extra: {seriesId: "s1", seriesIndex: 0}});
  const second = await seedEvent({owner, extra: {seriesId: "s1", seriesIndex: 1}});
  await notifyEventAudience(first);
  await notifyEventAudience(second);
  assert.equal((await notesOf(f, first)).length, 1);
  assert.equal((await notesOf(f, second)).length, 0);
});

test("recountSaves: kayıt sayısı tüm kullanıcılardan sayılır ve etkinlikte güncellenir", async () => {
  const {recountSaves} = require("../lib/events/on_saved_written");
  const owner = `o_${rid()}`;
  const eventId = await seedEvent({owner});
  const other = await seedEvent({owner});
  for (const uid of ["u1", "u2", "u3"]) {
    await db.doc(`users/${uid}_${eventId}/saved/${eventId}`).set({eventId, savedAt: Timestamp.now()});
  }
  await db.doc(`users/ux_${other}/saved/${other}`).set({eventId: other, savedAt: Timestamp.now()});

  assert.equal(await recountSaves(eventId), 3);
  assert.equal((await db.doc(`events/${eventId}`).get()).get("saveCount"), 3);
  assert.equal(await recountSaves(other), 1);

  await db.doc(`users/u1_${eventId}/saved/${eventId}`).delete();
  assert.equal(await recountSaves(eventId), 2);
  assert.equal((await db.doc(`events/${eventId}`).get()).get("saveCount"), 2);

  assert.equal(await recountSaves("yok_etkinlik"), 0);
});
