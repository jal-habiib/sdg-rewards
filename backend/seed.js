const admin = require("firebase-admin");
const crypto = require("crypto");

// ─── Firebase Admin Init ────────────────────────────────────────────────────
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ─── HMAC Helper ─────────────────────────────────────────────────────────────
const SECRET = "super-secret-hackathon-key-2026";

function generateSignature(codeId, campaignId, points) {
  const payload = `${codeId}${campaignId}${points}`;
  return crypto.createHmac("sha256", SECRET).update(payload).digest("hex");
}

// ─── Seed Data ───────────────────────────────────────────────────────────────
async function seed() {
  console.log("Starting Firestore seed...\n");

  // ── 1. programs/nutrition ──────────────────────────────────────────────────
  await db.collection("programs").doc("nutrition").set({
    name: "Nutrition Points",
    pool_deposited: 1000000,
    pool_reserved: 0,
    pool_spent: 0,
    pool_available: 1000000,
  });
  console.log("✓ programs/nutrition seeded");

  // ── 2. campaigns/buy-vegetables ───────────────────────────────────────────
  await db.collection("campaigns").doc("buy-vegetables").set({
    points_per_action: 50,
  });
  console.log("✓ campaigns/buy-vegetables seeded");

  // ── 3. rewards/veg-discount ───────────────────────────────────────────────
  await db.collection("rewards").doc("veg-discount").set({
    points_cost: 50,
    ugx_value: 2000,
  });
  console.log("✓ rewards/veg-discount seeded");

  // ── 4. users/mama-alice ───────────────────────────────────────────────────
  await db.collection("users").doc("mama-alice").set({
    phone: "+256772123456",
  });
  console.log("✓ users/mama-alice seeded");

  // ── 5. balances/mama-alice_nutrition ─────────────────────────────────────
  await db.collection("balances").doc("mama-alice_nutrition").set({
    points: 0,
  });
  console.log("✓ balances/mama-alice_nutrition seeded");

  // ── 6. partners/mama-alice-shop ───────────────────────────────────────────
  await db.collection("partners").doc("mama-alice-shop").set({
    name: "Mama Alice's Veg Shop",
  });
  console.log("✓ partners/mama-alice-shop seeded");

  // ── 7. codes (3 QR codes) ─────────────────────────────────────────────────
  const CAMPAIGN_ID = "buy-vegetables";
  const POINTS = 50;

  const codes = [
    "NUT-2025-000001",
    "NUT-2025-000002",
    "NUT-2025-000003",
  ];

  for (const codeId of codes) {
    const signature = generateSignature(codeId, CAMPAIGN_ID, POINTS);

    // Build and stringify the qr_data payload (encoded into the physical QR code)
    const qr_data = JSON.stringify({
      code: codeId,
      campaign: CAMPAIGN_ID,
      points: POINTS,
      sig: signature,
    });

    await db.collection("codes").doc(codeId).set({
      code_id: codeId,
      campaign_id: CAMPAIGN_ID,
      points: POINTS,
      signature,
      qr_data,
      status: "unused",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`\n✓ codes/${codeId} seeded`);
    console.log(`  qr_data → ${qr_data}`);
  }

  console.log("\n✅ All seed data written to Firestore successfully.");
  process.exit(0);
}

seed().catch((err) => {
  console.error("❌ Seed failed:", err);
  process.exit(1);
});
