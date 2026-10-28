// Rota - storage.rules testleri (Firebase Storage Emulator ile çalışır).
const {readFileSync} = require("node:fs");
const {before, after, describe, it} = require("node:test");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {ref, uploadString, deleteObject, getBytes} = require("firebase/storage");

const OWNER = "owner1";
const BOB = "bob";

let testEnv;

const [host, portText] = (process.env.FIREBASE_STORAGE_EMULATOR_HOST || "127.0.0.1:9199").split(":");

const storageOf = (uid, verified = true) =>
  testEnv.authenticatedContext(uid, {email_verified: verified}).storage();

const jpeg = {contentType: "image/jpeg"};

describe("storage (etkinlik fotoğrafları)", () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: "demo-rota",
      storage: {
        rules: readFileSync("storage.rules", "utf8"),
        host,
        port: Number(portText),
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  it("sahip kendi klasörüne görsel yükleyebilir", async () => {
    await assertSucceeds(uploadString(ref(storageOf(OWNER), "events/owner1/a.jpg"), "abc", "raw", jpeg));
  });

  it("başkasının klasörüne yazılamaz", async () => {
    await assertFails(uploadString(ref(storageOf(BOB), "events/owner1/b.jpg"), "abc", "raw", jpeg));
  });

  it("girişsiz ve e-postası doğrulanmamış kullanıcı yazamaz", async () => {
    await assertFails(
      uploadString(ref(testEnv.unauthenticatedContext().storage(), "events/owner1/c.jpg"), "abc", "raw", jpeg)
    );
    await assertFails(uploadString(ref(storageOf(OWNER, false), "events/owner1/d.jpg"), "abc", "raw", jpeg));
  });

  it("görsel olmayan tür reddedilir", async () => {
    await assertFails(
      uploadString(ref(storageOf(OWNER), "events/owner1/e.jpg"), "abc", "raw", {contentType: "text/html"})
    );
  });

  it("3 MB ve üstü reddedilir", async () => {
    const big = "a".repeat(3 * 1024 * 1024 + 10);
    await assertFails(uploadString(ref(storageOf(OWNER), "events/owner1/f.jpg"), big, "raw", jpeg));
  });

  it("giriş yapan okuyabilir, girişsiz okuyamaz; yalnızca sahip siler", async () => {
    await assertSucceeds(uploadString(ref(storageOf(OWNER), "events/owner1/g.jpg"), "abc", "raw", jpeg));
    await assertSucceeds(getBytes(ref(storageOf(BOB), "events/owner1/g.jpg")));
    await assertFails(getBytes(ref(testEnv.unauthenticatedContext().storage(), "events/owner1/g.jpg")));
    await assertFails(deleteObject(ref(storageOf(BOB), "events/owner1/g.jpg")));
    await assertSucceeds(deleteObject(ref(storageOf(OWNER), "events/owner1/g.jpg")));
  });

  it("tanımsız yollar kapalıdır", async () => {
    await assertFails(uploadString(ref(storageOf(OWNER), "baska/yol.jpg"), "abc", "raw", jpeg));
  });
});
