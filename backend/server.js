require("dotenv").config();

const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const ParkingSnapshot = require("./models/ParkingSnapshot");

const app = express();
const PORT = Number(process.env.PORT || 3000);
const VALID_SLOTS = ["A1", "A2", "A3", "A4", "B1", "B2", "B3", "B4"];

app.use(cors({
  origin: process.env.CORS_ORIGIN || "*"
}));
app.use(express.json({ limit: "32kb" }));

app.get("/api/health", (_req, res) => {
  res.json({
    success: true,
    service: "smart-parking-backend",
    database: mongoose.connection.readyState === 1 ? "connected" : "disconnected",
    timestamp: new Date().toISOString()
  });
});

app.post("/api/parking", async (req, res) => {
  try {
    const body = req.body || {};
    const incomingSlots = body.slots;

    if (!incomingSlots || typeof incomingSlots !== "object" || Array.isArray(incomingSlots)) {
      return res.status(400).json({ success: false, message: "slots must be an object of slot IDs and 0/1 values" });
    }

    const slotEntries = Object.entries(incomingSlots);
    if (slotEntries.length === 0 || slotEntries.some(([name, value]) =>
      !VALID_SLOTS.includes(name) || ![0, 1].includes(value)
    )) {
      return res.status(400).json({ success: false, message: "Provide valid slot IDs (A1-B4) with values 0 (available) or 1 (occupied)" });
    }

    // Merge partial camera payloads with the latest known state so a 4-slot
    // camera setup can coexist with the app's 8-slot layout.
    let latest = await ParkingSnapshot.findOne().sort({ createdAt: -1 });
    const mergedSlots = Object.fromEntries(VALID_SLOTS.map((name) => [name, 0]));

    if (latest && latest.slots) {
      for (const [name, value] of latest.slots.entries()) mergedSlots[name] = value;
    }
    Object.assign(mergedSlots, Object.fromEntries(slotEntries));

    const occupiedSlots = Object.values(mergedSlots).reduce((sum, value) => sum + value, 0);
    const availableSlots = VALID_SLOTS.length - occupiedSlots;

    const recommendedSlot = VALID_SLOTS.find((name) => mergedSlots[name] === 0) || "PARKING FULL";

    // Respect the detector's recommendation only if it is a valid currently free slot.
    const requestedRecommendation = body.recommendedSlot;
    const finalRecommendation =
      typeof requestedRecommendation === "string" &&
      VALID_SLOTS.includes(requestedRecommendation) &&
      mergedSlots[requestedRecommendation] === 0
        ? requestedRecommendation
        : recommendedSlot;

    const snapshot = await ParkingSnapshot.create({
      slots: mergedSlots,
      availableSlots,
      occupiedSlots,
      recommendedSlot: finalRecommendation
    });

    return res.status(201).json({
      success: true,
      message: "Parking status saved",
      data: {
        slots: Object.fromEntries(snapshot.slots),
        availableSlots: snapshot.availableSlots,
        occupiedSlots: snapshot.occupiedSlots,
        recommendedSlot: snapshot.recommendedSlot,
        updatedAt: snapshot.createdAt
      }
    });
  } catch (error) {
    console.error("POST /api/parking:", error);
    return res.status(500).json({ success: false, message: "Unable to save parking status" });
  }
});

app.get("/api/parking", async (_req, res) => {
  try {
    const snapshot = await ParkingSnapshot.findOne().sort({ createdAt: -1 }).lean();
    if (!snapshot) {
      return res.json({
        success: true,
        data: {
          slots: Object.fromEntries(VALID_SLOTS.map((name) => [name, 0])),
          availableSlots: 8,
          occupiedSlots: 0,
          recommendedSlot: "A1",
          updatedAt: null
        }
      });
    }

    return res.json({
      success: true,
      data: {
        slots: snapshot.slots,
        availableSlots: snapshot.availableSlots,
        occupiedSlots: snapshot.occupiedSlots,
        recommendedSlot: snapshot.recommendedSlot,
        updatedAt: snapshot.createdAt
      }
    });
  } catch (error) {
    console.error("GET /api/parking:", error);
    return res.status(500).json({ success: false, message: "Unable to read parking status" });
  }
});

app.get("/api/parking/history", async (req, res) => {
  try {
    const parsedLimit = Number.parseInt(req.query.limit, 10);
    const limit = Number.isFinite(parsedLimit) ? Math.min(Math.max(parsedLimit, 1), 100) : 20;
    const history = await ParkingSnapshot.find()
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();

    return res.json({
      success: true,
      count: history.length,
      data: history.map((item) => ({
        slots: item.slots,
        availableSlots: item.availableSlots,
        occupiedSlots: item.occupiedSlots,
        recommendedSlot: item.recommendedSlot,
        updatedAt: item.createdAt
      }))
    });
  } catch (error) {
    console.error("GET /api/parking/history:", error);
    return res.status(500).json({ success: false, message: "Unable to read parking history" });
  }
});

async function start() {
  const mongoUri = process.env.MONGODB_URI;
  if (!mongoUri) {
    console.error("MONGODB_URI is missing. Copy .env.example to .env and configure MongoDB.");
    process.exit(1);
  }

  try {
    await mongoose.connect(mongoUri);
    console.log("MongoDB connected");
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`Smart Parking API running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("MongoDB connection failed:", error.message);
    process.exit(1);
  }
}

start();
