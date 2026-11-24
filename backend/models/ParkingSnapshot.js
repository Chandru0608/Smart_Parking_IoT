const mongoose = require("mongoose");

const parkingSnapshotSchema = new mongoose.Schema(
  {
    slots: {
      type: Map,
      of: { type: Number, enum: [0, 1] },
      required: true
    },
    availableSlots: { type: Number, required: true, min: 0, max: 8 },
    recommendedSlot: { type: String, required: true, maxlength: 20 },
    occupiedSlots: { type: Number, required: true, min: 0, max: 8 },
    source: { type: String, default: "camera" }
  },
  { timestamps: true, versionKey: false }
);

module.exports = mongoose.model("ParkingSnapshot", parkingSnapshotSchema);
