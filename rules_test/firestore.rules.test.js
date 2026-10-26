// Rota - firestore.rules testleri (Firebase Emulator ile çalışır).
// Çalıştırma: rules_test klasöründe `npm install` sonra `npm test`.
const {readFileSync} = require("node:fs");
const {before, after, beforeEach, describe, it} = require("node:test");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {
  Timestamp,
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} = require("firebase/firestore");

const OWNER = "owner1";
const ALICE = "alice";
const BOB = "bob";
const EVENT = "event1";

let testEnv;

const [host, portText] = (process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080").split(":");

const tomorrow = () => Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000));

const validProfile = () => ({
  displayName: "Ali Veli",
  bio: "",
  city: "Elazığ",
  interests: ["yoga"],
  createdAt: serverTimestamp(),
});

const validEvent = (ownerId = OWNER) => ({
  ownerId,
  ownerName: "Sahip",
  title: "Fırat kenarında yoga",
  description: "",
  category: "yoga",
  city: "Elazığ",
  district: "",
  startsAt: tomorrow(),
  capacity: 5,
  acceptedCount: 0,
  status: "active",
  createdAt: serverTimestamp(),
});

const validReport = (reporterId) => ({
  reporterId,
  targetType: "event",
  targetId: EVENT,
  reason: "spam",
  details: "",
  status: "open",
  createdAt: serverTimestamp(),
});

/** Kuralları atlayarak başlangıç verisi yazar. */
async function seed(callback) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await callback(context.firestore());
  });
}

const dbOf = (uid) =>
  testEnv.authenticatedContext(uid, {email_verified: true}).firestore();
const unverifiedDb = (uid) =>
  testEnv.authenticatedContext(uid, {email_verified: false}).firestore();
const anonDb = () => testEnv.unauthenticatedContext().firestore();

async function seedEvent(overrides = {}) {
  await seed(async (db) => {
    await setDoc(doc(db, "events", EVENT), {
      ...validEvent(),
      createdAt: Timestamp.now(),
      ...overrides,
    });
    await setDoc(doc(db, "events", EVENT, "private", "location"), {
      address: "Gizli adres 12",
    });
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-rota",
    firestore: {
      rules: readFileSync("firestore.rules", "utf8"),
      host,
      port: Number(portText),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe("users", () => {
  it("kullanıcı kendi profilini oluşturabilir", async () => {
    await assertSucceeds(setDoc(doc(dbOf(ALICE), "users", ALICE), validProfile()));
  });

  it("başkası adına profil oluşturulamaz", async () => {
    await assertFails(setDoc(doc(dbOf(BOB), "users", ALICE), validProfile()));
  });

  it("girişsiz kullanıcı profil okuyamaz", async () => {
    await seed((db) => setDoc(doc(db, "users", ALICE), {...validProfile(), createdAt: Timestamp.now()}));
    await assertFails(getDoc(doc(anonDb(), "users", ALICE)));
  });

  it("geçersiz profil (ad çok kısa) reddedilir", async () => {
    await assertFails(
      setDoc(doc(dbOf(ALICE), "users", ALICE), {...validProfile(), displayName: "A"})
    );
  });

  it("createdAt sonradan değiştirilemez", async () => {
    await seed((db) => setDoc(doc(db, "users", ALICE), {...validProfile(), createdAt: Timestamp.now()}));
    await assertFails(
      updateDoc(doc(dbOf(ALICE), "users", ALICE), {createdAt: Timestamp.fromDate(new Date(2000, 0, 1))})
    );
  });

  it("kendi profilini güncelleyebilir, başkasınınkini güncelleyemez", async () => {
    await seed((db) => setDoc(doc(db, "users", ALICE), {...validProfile(), createdAt: Timestamp.now()}));
    await assertSucceeds(updateDoc(doc(dbOf(ALICE), "users", ALICE), {bio: "Merhaba"}));
    await assertFails(updateDoc(doc(dbOf(BOB), "users", ALICE), {bio: "Hacked"}));
  });

  it("profil silinemez (hesap silme sunucuda)", async () => {
    await seed((db) => setDoc(doc(db, "users", ALICE), {...validProfile(), createdAt: Timestamp.now()}));
    await assertFails(deleteDoc(doc(dbOf(ALICE), "users", ALICE)));
  });

  it("engel listesi yalnızca sahibine açık", async () => {
    await assertSucceeds(
      setDoc(doc(dbOf(ALICE), "users", ALICE, "blocks", BOB), {createdAt: serverTimestamp()})
    );
    await assertFails(
      setDoc(doc(dbOf(BOB), "users", ALICE, "blocks", "x"), {createdAt: serverTimestamp()})
    );
    await assertFails(getDoc(doc(dbOf(BOB), "users", ALICE, "blocks", BOB)));
  });

  it("kendini engelleyemez", async () => {
    await assertFails(
      setDoc(doc(dbOf(ALICE), "users", ALICE, "blocks", ALICE), {createdAt: serverTimestamp()})
    );
  });
});

describe("fcmTokens (push jetonları)", () => {
  const tokenRef = (db, uid, token = "tok:abc_123") =>
    doc(db, "users", uid, "fcmTokens", token);

  it("kullanıcı kendi jetonunu kaydedebilir", async () => {
    await assertSucceeds(
      setDoc(tokenRef(dbOf(ALICE), ALICE), {platform: "android", updatedAt: serverTimestamp()})
    );
  });

  it("başkası adına jeton kaydedilemez", async () => {
    await assertFails(
      setDoc(tokenRef(dbOf(BOB), ALICE), {platform: "android", updatedAt: serverTimestamp()})
    );
  });

  it("geçersiz platform veya fazladan alan reddedilir", async () => {
    await assertFails(
      setDoc(tokenRef(dbOf(ALICE), ALICE), {platform: "windows", updatedAt: serverTimestamp()})
    );
    await assertFails(
      setDoc(tokenRef(dbOf(ALICE), ALICE), {
        platform: "ios",
        updatedAt: serverTimestamp(),
        extra: 1,
      })
    );
  });

  it("kullanıcı kendi jetonunu siler, başkasınınkini okuyamaz", async () => {
    await seed((db) => setDoc(tokenRef(db, ALICE), {platform: "android", updatedAt: Timestamp.now()}));
    await assertFails(getDoc(tokenRef(dbOf(BOB), ALICE)));
    await assertSucceeds(deleteDoc(tokenRef(dbOf(ALICE), ALICE)));
  });
});

describe("events", () => {
  it("etkinlik ve tam adres tek batch ile oluşturulabilir", async () => {
    const db = dbOf(OWNER);
    const batch = writeBatch(db);
    batch.set(doc(db, "events", EVENT), validEvent());
    batch.set(doc(db, "events", EVENT, "private", "location"), {address: "Gizli adres 12"});
    await assertSucceeds(batch.commit());
  });

  it("başkası adına etkinlik oluşturulamaz", async () => {
    await assertFails(setDoc(doc(dbOf(BOB), "events", EVENT), validEvent(OWNER)));
  });

  it("acceptedCount 0 dışında başlatılamaz", async () => {
    await assertFails(
      setDoc(doc(dbOf(OWNER), "events", EVENT), {...validEvent(), acceptedCount: 3})
    );
  });

  it("geçmiş tarihli etkinlik oluşturulamaz", async () => {
    await assertFails(
      setDoc(doc(dbOf(OWNER), "events", EVENT), {
        ...validEvent(),
        startsAt: Timestamp.fromDate(new Date(2000, 0, 1)),
      })
    );
  });

  it("kapasite 1-100 dışında olamaz", async () => {
    await assertFails(setDoc(doc(dbOf(OWNER), "events", EVENT), {...validEvent(), capacity: 0}));
    await assertFails(setDoc(doc(dbOf(OWNER), "events", EVENT), {...validEvent(), capacity: 101}));
  });

  it("giriş yapan herkes etkinliği okuyabilir, girişsiz okuyamaz", async () => {
    await seedEvent();
    await assertSucceeds(getDoc(doc(dbOf(BOB), "events", EVENT)));
    await assertFails(getDoc(doc(anonDb(), "events", EVENT)));
  });

  it("sahip düzenleyebilir, başkası düzenleyemez", async () => {
    await seedEvent();
    await assertSucceeds(updateDoc(doc(dbOf(OWNER), "events", EVENT), {title: "Yeni başlık"}));
    await assertFails(updateDoc(doc(dbOf(BOB), "events", EVENT), {title: "Hacked"}));
  });

  it("sahip bile acceptedCount değerini değiştiremez", async () => {
    await seedEvent();
    await assertFails(updateDoc(doc(dbOf(OWNER), "events", EVENT), {acceptedCount: 4}));
  });

  it("sahip ownerId değerini değiştiremez", async () => {
    await seedEvent();
    await assertFails(updateDoc(doc(dbOf(OWNER), "events", EVENT), {ownerId: BOB}));
  });

  it("kapasite onaylı katılımcı sayısının altına düşürülemez", async () => {
    await seedEvent({acceptedCount: 3});
    await assertFails(updateDoc(doc(dbOf(OWNER), "events", EVENT), {capacity: 2}));
    await assertSucceeds(updateDoc(doc(dbOf(OWNER), "events", EVENT), {capacity: 3}));
  });

  it("etkinlik silinemez", async () => {
    await seedEvent();
    await assertFails(deleteDoc(doc(dbOf(OWNER), "events", EVENT)));
  });
});

describe("private/location (konum gizliliği)", () => {
  it("sahip okuyabilir", async () => {
    await seedEvent();
    await assertSucceeds(getDoc(doc(dbOf(OWNER), "events", EVENT, "private", "location")));
  });

  it("onaylı katılımcı okuyabilir", async () => {
    await seedEvent();
    await seed((db) =>
      setDoc(doc(db, "events", EVENT, "participants", ALICE), {
        userId: ALICE,
        userName: "Ali",
        joinedAt: Timestamp.now(),
      })
    );
    await assertSucceeds(getDoc(doc(dbOf(ALICE), "events", EVENT, "private", "location")));
  });

  it("katılımcı olmayan okuyamaz", async () => {
    await seedEvent();
    await assertFails(getDoc(doc(dbOf(BOB), "events", EVENT, "private", "location")));
  });

  it("bekleyen talep sahibi okuyamaz", async () => {
    await seedEvent();
    await seed((db) =>
      setDoc(doc(db, "events", EVENT, "requests", BOB), {
        userId: BOB,
        userName: "Bob",
        status: "pending",
        createdAt: Timestamp.now(),
      })
    );
    await assertFails(getDoc(doc(dbOf(BOB), "events", EVENT, "private", "location")));
  });

  it("başkası konum yazamaz", async () => {
    await seedEvent();
    await assertFails(
      setDoc(doc(dbOf(BOB), "events", EVENT, "private", "location"), {address: "Sahte adres"})
    );
  });
});

describe("requests (katılım talepleri)", () => {
  const requestRef = (db, uid) => doc(db, "events", EVENT, "requests", uid);
  const newRequest = (uid) => ({
    userId: uid,
    userName: "Kullanıcı",
    status: "pending",
    createdAt: serverTimestamp(),
  });

  it("kullanıcı kendi adına talep gönderebilir", async () => {
    await seedEvent();
    await assertSucceeds(setDoc(requestRef(dbOf(ALICE), ALICE), newRequest(ALICE)));
  });

  it("başkası adına talep gönderilemez", async () => {
    await seedEvent();
    await assertFails(setDoc(requestRef(dbOf(BOB), ALICE), newRequest(ALICE)));
  });

  it("etkinlik sahibi kendi etkinliğine talep gönderemez", async () => {
    await seedEvent();
    await assertFails(setDoc(requestRef(dbOf(OWNER), OWNER), newRequest(OWNER)));
  });

  it("iptal edilmiş etkinliğe talep gönderilemez", async () => {
    await seedEvent({status: "cancelled"});
    await assertFails(setDoc(requestRef(dbOf(ALICE), ALICE), newRequest(ALICE)));
  });

  it("talep doğrudan 'approved' olarak oluşturulamaz", async () => {
    await seedEvent();
    await assertFails(
      setDoc(requestRef(dbOf(ALICE), ALICE), {...newRequest(ALICE), status: "approved"})
    );
  });

  it("kullanıcı bekleyen talebini geri çekebilir", async () => {
    await seedEvent();
    await seed((db) => setDoc(requestRef(db, ALICE), {...newRequest(ALICE), createdAt: Timestamp.now()}));
    await assertSucceeds(updateDoc(requestRef(dbOf(ALICE), ALICE), {status: "cancelled"}));
  });

  it("kullanıcı kendi talebini 'approved' yapamaz", async () => {
    await seedEvent();
    await seed((db) => setDoc(requestRef(db, ALICE), {...newRequest(ALICE), createdAt: Timestamp.now()}));
    await assertFails(updateDoc(requestRef(dbOf(ALICE), ALICE), {status: "approved"}));
  });

  it("etkinlik sahibi talebi istemciden onaylayamaz (yalnızca Cloud Functions)", async () => {
    await seedEvent();
    await seed((db) => setDoc(requestRef(db, ALICE), {...newRequest(ALICE), createdAt: Timestamp.now()}));
    await assertFails(updateDoc(requestRef(dbOf(OWNER), ALICE), {status: "approved"}));
  });

  it("reddedilen talep yeniden açılamaz", async () => {
    await seedEvent();
    await seed((db) =>
      setDoc(requestRef(db, ALICE), {...newRequest(ALICE), status: "rejected", createdAt: Timestamp.now()})
    );
    await assertFails(updateDoc(requestRef(dbOf(ALICE), ALICE), {status: "pending"}));
  });

  it("geri çekilen talep yeniden açılabilir", async () => {
    await seedEvent();
    await seed((db) =>
      setDoc(requestRef(db, ALICE), {...newRequest(ALICE), status: "cancelled", createdAt: Timestamp.now()})
    );
    await assertSucceeds(updateDoc(requestRef(dbOf(ALICE), ALICE), {status: "pending"}));
  });

  it("başkasının talebi okunamaz, sahip okuyabilir", async () => {
    await seedEvent();
    await seed((db) => setDoc(requestRef(db, ALICE), {...newRequest(ALICE), createdAt: Timestamp.now()}));
    await assertFails(getDoc(requestRef(dbOf(BOB), ALICE)));
    await assertSucceeds(getDoc(requestRef(dbOf(OWNER), ALICE)));
    await assertSucceeds(getDoc(requestRef(dbOf(ALICE), ALICE)));
  });

  it("talep listesini yalnızca sahip görebilir", async () => {
    await seedEvent();
    await assertSucceeds(getDocs(collection(dbOf(OWNER), "events", EVENT, "requests")));
    await assertFails(getDocs(collection(dbOf(BOB), "events", EVENT, "requests")));
  });
});

describe("participants (katılımcılar)", () => {
  it("istemci katılımcı ekleyemez", async () => {
    await seedEvent();
    await assertFails(
      setDoc(doc(dbOf(ALICE), "events", EVENT, "participants", ALICE), {
        userId: ALICE,
        userName: "Ali",
        joinedAt: serverTimestamp(),
      })
    );
    await assertFails(
      setDoc(doc(dbOf(OWNER), "events", EVENT, "participants", ALICE), {
        userId: ALICE,
        userName: "Ali",
        joinedAt: serverTimestamp(),
      })
    );
  });

  it("katılımcı listesini yabancı görmez, sahip ve katılımcı görür", async () => {
    await seedEvent();
    await seed((db) =>
      setDoc(doc(db, "events", EVENT, "participants", ALICE), {
        userId: ALICE,
        userName: "Ali",
        joinedAt: Timestamp.now(),
      })
    );
    const path = ["events", EVENT, "participants"];
    await assertFails(getDocs(collection(dbOf(BOB), ...path)));
    await assertSucceeds(getDocs(collection(dbOf(OWNER), ...path)));
    await assertSucceeds(getDocs(collection(dbOf(ALICE), ...path)));
  });

  it("'katıldığım etkinlikler' sorgusu yalnızca kendi kayıtları için çalışır", async () => {
    await seedEvent();
    await seed((db) =>
      setDoc(doc(db, "events", EVENT, "participants", ALICE), {
        userId: ALICE,
        userName: "Ali",
        joinedAt: Timestamp.now(),
      })
    );
    await assertSucceeds(
      getDocs(query(collectionGroup(dbOf(ALICE), "participants"), where("userId", "==", ALICE)))
    );
    await assertFails(
      getDocs(query(collectionGroup(dbOf(BOB), "participants"), where("userId", "==", ALICE)))
    );
  });
});

describe("notifications (bildirimler)", () => {
  const itemRef = (db, uid) => doc(db, "notifications", uid, "items", "n1");
  const item = () => ({
    type: "request_approved",
    eventId: EVENT,
    eventTitle: "Yoga",
    read: false,
    createdAt: Timestamp.now(),
  });

  it("kullanıcı kendi bildirimini okur, başkasınınkini okuyamaz", async () => {
    await seed((db) => setDoc(itemRef(db, ALICE), item()));
    await assertSucceeds(getDoc(itemRef(dbOf(ALICE), ALICE)));
    await assertFails(getDoc(itemRef(dbOf(BOB), ALICE)));
  });

  it("yalnızca 'read' alanı güncellenebilir", async () => {
    await seed((db) => setDoc(itemRef(db, ALICE), item()));
    await assertSucceeds(updateDoc(itemRef(dbOf(ALICE), ALICE), {read: true}));
    await assertFails(updateDoc(itemRef(dbOf(ALICE), ALICE), {eventTitle: "Değişti"}));
  });

  it("istemci bildirim oluşturamaz veya silemez", async () => {
    await assertFails(setDoc(itemRef(dbOf(ALICE), ALICE), item()));
    await seed((db) => setDoc(itemRef(db, ALICE), item()));
    await assertFails(deleteDoc(itemRef(dbOf(ALICE), ALICE)));
  });
});

describe("reports (şikâyetler)", () => {
  it("giriş yapan kullanıcı kendi adına şikâyet oluşturabilir", async () => {
    await assertSucceeds(setDoc(doc(dbOf(ALICE), "reports", "r1"), validReport(ALICE)));
  });

  it("başkası adına şikâyet oluşturulamaz", async () => {
    await assertFails(setDoc(doc(dbOf(BOB), "reports", "r1"), validReport(ALICE)));
  });

  it("geçersiz neden reddedilir", async () => {
    await assertFails(
      setDoc(doc(dbOf(ALICE), "reports", "r1"), {...validReport(ALICE), reason: "hoslanmadim"})
    );
  });

  it("şikâyet okunamaz, güncellenemez, silinemez", async () => {
    await seed((db) => setDoc(doc(db, "reports", "r1"), {...validReport(ALICE), createdAt: Timestamp.now()}));
    await assertFails(getDoc(doc(dbOf(ALICE), "reports", "r1")));
    await assertFails(updateDoc(doc(dbOf(ALICE), "reports", "r1"), {status: "closed"}));
    await assertFails(deleteDoc(doc(dbOf(ALICE), "reports", "r1")));
  });
});

describe("messages (etkinlik sohbeti)", () => {
  const path = ["events", EVENT, "messages"];
  const msg = (senderId, extra = {}) => ({
    senderId,
    text: "Merhaba",
    createdAt: serverTimestamp(),
    ...extra,
  });

  async function seedChat() {
    await seedEvent();
    await seed(async (db) => {
      await setDoc(doc(db, "events", EVENT, "participants", ALICE), {
        userId: ALICE,
        userName: "Ali",
        joinedAt: Timestamp.now(),
      });
      await setDoc(doc(db, "events", EVENT, "messages", "m1"), {
        senderId: ALICE,
        text: "Selam",
        createdAt: Timestamp.now(),
      });
    });
  }

  it("sahip ve katılımcı yazabilir ve okuyabilir", async () => {
    await seedChat();
    await assertSucceeds(addDocMsg(dbOf(ALICE), msg(ALICE)));
    await assertSucceeds(addDocMsg(dbOf(OWNER), msg(OWNER)));
    await assertSucceeds(getDocs(collection(dbOf(ALICE), ...path)));
    await assertSucceeds(getDocs(collection(dbOf(OWNER), ...path)));
  });

  it("yabancı ve girişsiz kullanıcı okuyamaz ve yazamaz", async () => {
    await seedChat();
    await assertFails(getDocs(collection(dbOf(BOB), ...path)));
    await assertFails(addDocMsg(dbOf(BOB), msg(BOB)));
    await assertFails(getDocs(collection(anonDb(), ...path)));
    await assertFails(addDocMsg(anonDb(), msg(BOB)));
  });

  it("başkası adına mesaj yazılamaz", async () => {
    await seedChat();
    await assertFails(addDocMsg(dbOf(ALICE), msg(OWNER)));
  });

  it("geçersiz içerik reddedilir", async () => {
    await seedChat();
    await assertFails(addDocMsg(dbOf(ALICE), msg(ALICE, {text: ""})));
    await assertFails(addDocMsg(dbOf(ALICE), msg(ALICE, {text: "a".repeat(501)})));
    await assertFails(addDocMsg(dbOf(ALICE), msg(ALICE, {senderName: "Sahte"})));
    await assertFails(addDocMsg(dbOf(ALICE), msg(ALICE, {createdAt: Timestamp.now()})));
    await assertSucceeds(addDocMsg(dbOf(ALICE), msg(ALICE, {text: "a".repeat(500)})));
  });

  it("iptal edilmiş etkinlikte yazılamaz", async () => {
    await seedChat();
    await seed((db) => updateDoc(doc(db, "events", EVENT), {status: "cancelled"}));
    await assertFails(addDocMsg(dbOf(ALICE), msg(ALICE)));
    await assertSucceeds(getDocs(collection(dbOf(ALICE), ...path)));
  });

  it("mesaj güncellenemez; yalnızca gönderen veya sahip siler", async () => {
    await seedChat();
    await assertFails(updateDoc(doc(dbOf(ALICE), ...path, "m1"), {text: "değişti"}));
    await assertFails(deleteDoc(doc(dbOf(BOB), ...path, "m1")));
    await assertSucceeds(deleteDoc(doc(dbOf(ALICE), ...path, "m1")));
    await seed((db) =>
      setDoc(doc(db, "events", EVENT, "messages", "m2"), {
        senderId: ALICE,
        text: "x",
        createdAt: Timestamp.now(),
      })
    );
    await assertSucceeds(deleteDoc(doc(dbOf(OWNER), ...path, "m2")));
  });
});

function addDocMsg(db, data) {
  return setDoc(doc(collection(db, "events", EVENT, "messages")), data);
}

describe("e-posta doğrulaması", () => {
  it("doğrulanmamış kullanıcı profil, etkinlik ve sohbete erişemez", async () => {
    await seedEvent();
    const db = unverifiedDb(ALICE);
    await assertFails(setDoc(doc(db, "users", ALICE), validProfile()));
    await assertFails(setDoc(doc(db, "events", "yeni"), validEvent(ALICE)));
    await assertFails(getDoc(doc(db, "events", EVENT)));
    await assertFails(getDocs(collection(db, "events")));
  });

  it("doğrulanmış kullanıcı kendi profilini oluşturabilir", async () => {
    await assertSucceeds(setDoc(doc(dbOf(ALICE), "users", ALICE), validProfile()));
  });
});
