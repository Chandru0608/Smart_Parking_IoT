const mongoose = require("mongoose");

const parkingSnapshotSchema = new mongoose.Schema({
  slots: {
    A1: { type: Number, enum: [0, 1], required: true },
    A2: { type: Number, enum: [0, 1], required: true },
    B1: { type: Number, enum: [0, 1], required: true },
    B2: { type: Number, enum: [0, 1], required: true }
  },
  availableSlots: { type: Number, required: true, min: 0, max: 4 },
  occupiedSlots: { type: Number, required: true, min: 0, max: 4 },
  recommendedSlot: { type: String, required: true, maxlength: 20 }
}, { timestamps: true, versionKey: false });

module.exports = mongoose.model("ParkingSnapshot", parkingSnapshotSchema);
