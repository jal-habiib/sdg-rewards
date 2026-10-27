const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const crypto = require("crypto");

// ─── Firebase Admin Init ────────────────────────────────────────────────────
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ─── Express Setup ──────────────────────────────────────────────────────────
const app = express();
app.use(cors());
app.use(express.json({ limit: "10mb" }));

// ─── HMAC Helper ────────────────────────────────────────────────────────────
const SECRET = "super-secret-hackathon-key-2026";

/**
 * Generate an HMAC-SHA256 signature for a QR code payload.
 * Payload format: codeId + campaignId + points
 */
function generateSignature(codeId, campaignId, points) {
  const payload = `${codeId}${campaignId}${points}`;
  return crypto.createHmac("sha256", SECRET).update(payload).digest("hex");
}

/**
 * Verify that the signature embedded in qr_data matches the expected HMAC.
 * Expected qr_data shape: { codeId, campaignId, points, signature }
 */
function verifyQRSignature(qrData) {
  const { codeId, campaignId, points, signature } = qrData;
  if (!codeId || !campaignId || points === undefined || !signature) {
    return false;
  }
  const expected = generateSignature(codeId, campaignId, points);
  // Constant-time comparison to prevent timing attacks
  try {
    return crypto.timingSafeEqual(
      Buffer.from(expected, "hex"),
      Buffer.from(signature, "hex")
    );
  } catch {
    return false;
  }
}

// ─── POST /api/earn ─────────────────────────────────────────────────────────
/**
 * Body: { user_id, code_id, qr_data }
 * qr_data: { codeId, campaignId, points, signature }
 *
 * 1. Verify HMAC signature.
 * 2. Check code is unused in `codes` collection.
 * 3. Batch write:
 *    - Mark code as claimed.
 *    - Increment user balance +50 pts  (`balances/{user_id}_{programId}`).
 *    - Increment program pool_reserved +2000 UGX.
 *    - Decrement program pool_available -2000 UGX.
 *    - Create a transaction log entry.
 */
app.post("/api/earn", async (req, res) => {
  try {
    const { user_id, code_id, qr_data } = req.body;

    // Validate required fields
    if (!user_id || !code_id || !qr_data) {
      return res.status(400).json({ error: "Missing required fields: user_id, code_id, qr_data" });
    }

    // 1. Verify HMAC signature
    if (!verifyQRSignature(qr_data)) {
      return res.status(401).json({ error: "Invalid QR signature" });
    }

    const { campaignId, points } = qr_data;
    const POINTS_AWARD = 50;
    const UGX_VALUE = 2000;
    const PROGRAM_ID = "nutrition"; // derived from campaign context

    // 2. Fetch code document and verify it is unused
    const codeRef = db.collection("codes").doc(code_id);
    const codeSnap = await codeRef.get();

    if (!codeSnap.exists) {
      return res.status(404).json({ error: "QR code not found" });
    }

    const codeData = codeSnap.data();
    if (codeData.status !== "unused") {
      return res.status(409).json({ error: "QR code has already been claimed" });
    }

    // 3. Prepare Firestore references
    const balanceId = `${user_id}_${PROGRAM_ID}`;
    const balanceRef = db.collection("balances").doc(balanceId);
    const programRef = db.collection("programs").doc(PROGRAM_ID);
    const txRef = db.collection("transactions").doc(); // auto-id

    // 4. Execute batch write
    const batch = db.batch();

    // Mark code as claimed
    batch.update(codeRef, {
      status: "claimed",
      claimed_by: user_id,
      claimed_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Increment user balance
    batch.update(balanceRef, {
      points: admin.firestore.FieldValue.increment(POINTS_AWARD),
    });

    // Update program pool
    batch.update(programRef, {
      pool_reserved: admin.firestore.FieldValue.increment(UGX_VALUE),
      pool_available: admin.firestore.FieldValue.increment(-UGX_VALUE),
    });

    // Create transaction log
    batch.set(txRef, {
      type: "earn",
      user_id,
      code_id,
      campaign_id: campaignId,
      points: POINTS_AWARD,
      ugx_value: UGX_VALUE,
      program_id: PROGRAM_ID,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return res.status(200).json({
      success: true,
      message: `Earned ${POINTS_AWARD} points!`,
      points_awarded: POINTS_AWARD,
      ugx_reserved: UGX_VALUE,
      balance_id: balanceId,
      transaction_id: txRef.id,
    });
  } catch (err) {
    console.error("Error in /api/earn:", err);
    return res.status(500).json({ error: "Internal server error", details: err.message });
  }
});

// ─── POST /api/spend ────────────────────────────────────────────────────────
/**
 * Body: { user_id, reward_id, partner_id }
 *
 * 1. Fetch reward to get points_cost and ugx_value.
 * 2. Check user balance >= points_cost.
 * 3. Batch write:
 *    - Deduct points from balance.
 *    - Move ugx_value from pool_reserved to pool_spent.
 *    - Create a spend transaction log entry.
 */
app.post("/api/spend", async (req, res) => {
  try {
    const { user_id, reward_id, partner_id } = req.body;

    // Validate required fields
    if (!user_id || !reward_id || !partner_id) {
      return res.status(400).json({ error: "Missing required fields: user_id, reward_id, partner_id" });
    }

    const PROGRAM_ID = "nutrition";
    const balanceId = `${user_id}_${PROGRAM_ID}`;

    // 1. Fetch reward document
    const rewardRef = db.collection("rewards").doc(reward_id);
    const rewardSnap = await rewardRef.get();

    if (!rewardSnap.exists) {
      return res.status(404).json({ error: "Reward not found" });
    }

    const rewardData = rewardSnap.data();
    const POINTS_COST = rewardData.points_cost ?? 50;
    const UGX_VALUE = rewardData.ugx_value ?? 2000;

    // 2. Fetch user balance
    const balanceRef = db.collection("balances").doc(balanceId);
    const balanceSnap = await balanceRef.get();

    if (!balanceSnap.exists) {
      return res.status(404).json({ error: "User balance not found" });
    }

    const { points: currentPoints } = balanceSnap.data();

    if (currentPoints < POINTS_COST) {
      return res.status(402).json({
        error: "Insufficient points",
        current_balance: currentPoints,
        required: POINTS_COST,
      });
    }

    // 3. Prepare references
    const programRef = db.collection("programs").doc(PROGRAM_ID);
    const txRef = db.collection("transactions").doc(); // auto-id

    // 4. Execute batch write
    const batch = db.batch();

    // Deduct points from balance
    batch.update(balanceRef, {
      points: admin.firestore.FieldValue.increment(-POINTS_COST),
    });

    // Move UGX from pool_reserved to pool_spent
    batch.update(programRef, {
      pool_reserved: admin.firestore.FieldValue.increment(-UGX_VALUE),
      pool_spent: admin.firestore.FieldValue.increment(UGX_VALUE),
    });

    // Create spend transaction log
    batch.set(txRef, {
      type: "spend",
      user_id,
      reward_id,
      partner_id,
      points_spent: POINTS_COST,
      ugx_value: UGX_VALUE,
      program_id: PROGRAM_ID,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return res.status(200).json({
      success: true,
      message: `Redeemed ${POINTS_COST} points for ${reward_id}!`,
      points_spent: POINTS_COST,
      ugx_disbursed: UGX_VALUE,
      transaction_id: txRef.id,
    });
  } catch (err) {
    console.error("Error in /api/spend:", err);
    return res.status(500).json({ error: "Internal server error", details: err.message });
  }
});

// ─── Health Check ────────────────────────────────────────────────────────────
app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// ─── Start Server ────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`SDG Rewards backend running on port ${PORT}`);
});
