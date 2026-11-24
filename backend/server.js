require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const ParkingSnapshot = require("./models/ParkingSnapshot");

const app = express();
const PORT = Number(process.env.PORT || 3000);
const VALID_SLOTS = ["A1", "A2", "B1", "B2"];

app.use(cors({ origin: process.env.CORS_ORIGIN || "*" }));
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
    const incoming = req.body?.slots;
    if (!incoming || typeof incoming !== "object" || Array.isArray(incoming)) {
      return res.status(400).json({ success: false, message: "slots must be an object" });
    }
    const entries = Object.entries(incoming);
    if (entries.length !== VALID_SLOTS.length ||
        entries.some(([name, value]) => !VALID_SLOTS.includes(name) || ![0, 1].includes(value)) ||
        VALID_SLOTS.some(name => !Object.prototype.hasOwnProperty.call(incoming, name))) {
      return res.status(400).json({ success: false, message: "Send exactly A1, A2, B1 and B2; use 0 for available and 1 for occupied" });
    }

    const slots = Object.fromEntries(VALID_SLOTS.map(name => [name, incoming[name]]));
    const occupiedSlots = Object.values(slots).reduce((sum, value) => sum + value, 0);
    const availableSlots = VALID_SLOTS.length - occupiedSlots;
    const firstFree = VALID_SLOTS.find(name => slots[name] === 0) || "PARKING FULL";
    const requested = req.body.recommendedSlot;
    const recommendedSlot = VALID_SLOTS.includes(requested) && slots[requested] === 0 ? requested : firstFree;

    const snapshot = await ParkingSnapshot.create({
      slots, availableSlots, occupiedSlots, recommendedSlot
    });
    res.status(201).json({
      success: true,
      message: "Parking status saved",
      data: { slots, availableSlots, occupiedSlots, recommendedSlot, updatedAt: snapshot.createdAt }
    });
  } catch (error) {
    console.error("POST /api/parking:", error);
    res.status(500).json({ success: false, message: "Unable to save parking status" });
  }
});

app.get("/api/parking", async (_req, res) => {
  try {
    const snapshot = await ParkingSnapshot.findOne().sort({ createdAt: -1 }).lean();
    if (!snapshot) {
      return res.json({ success: true, data: {
        slots: { A1: 0, A2: 0, B1: 0, B2: 0 },
        availableSlots: 4, occupiedSlots: 0, recommendedSlot: "A1", updatedAt: null
      }});
    }
    res.json({ success: true, data: {
      slots: snapshot.slots, availableSlots: snapshot.availableSlots,
      occupiedSlots: snapshot.occupiedSlots, recommendedSlot: snapshot.recommendedSlot,
      updatedAt: snapshot.createdAt
    }});
  } catch (error) {
    console.error("GET /api/parking:", error);
    res.status(500).json({ success: false, message: "Unable to read parking status" });
  }
});

app.get("/api/parking/history", async (req, res) => {
  try {
    const n = Number.parseInt(req.query.limit, 10);
    const limit = Number.isFinite(n) ? Math.min(Math.max(n, 1), 100) : 20;
    const history = await ParkingSnapshot.find().sort({ createdAt: -1 }).limit(limit).lean();
    res.json({ success: true, count: history.length, data: history.map(item => ({
      slots: item.slots, availableSlots: item.availableSlots,
      occupiedSlots: item.occupiedSlots, recommendedSlot: item.recommendedSlot,
      updatedAt: item.createdAt
    }))});
  } catch (error) {
    console.error("GET /api/parking/history:", error);
    res.status(500).json({ success: false, message: "Unable to read parking history" });
  }
});

async function start() {
  if (!process.env.MONGODB_URI) {
    console.error("MONGODB_URI is missing. Copy .env.example to .env and configure MongoDB.");
    process.exit(1);
  }
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("MongoDB connected");
    app.listen(PORT, "0.0.0.0", () => console.log(`Smart Parking API running on http://localhost:${PORT}`));
  } catch (error) {
    console.error("MongoDB connection failed:", error.message);
    process.exit(1);
  }
}
start();
