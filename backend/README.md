# Smart Parking Backend

Node.js + Express + MongoDB REST API for the Smart Parking IoT project.

## Requirements

- Node.js 18 or newer
- MongoDB local service or a MongoDB Atlas database

## Setup (Windows PowerShell)

1. Open a terminal in the repository's `backend` folder.
2. Install dependencies:

   ```powershell
   npm install
   ```

3. Create your environment file:

   ```powershell
   Copy-Item .env.example .env
   ```

4. Open `.env` and set `MONGODB_URI`. For local MongoDB, the example URI works if MongoDB is running. For Atlas, paste your connection string and replace its password locally. Never commit `.env`.
5. Start the API:

   ```powershell
   npm start
   ```

The API listens on port 3000.

## Endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| GET | `/api/health` | API and database health |
| POST | `/api/parking` | Save the latest camera slot states |
| GET | `/api/parking` | Read the latest parking state |
| GET | `/api/parking/history?limit=20` | Read recent saved snapshots (1–100) |

### Camera POST payload

The existing Python detector posts this structure:

```json
{
  "slots": { "A1": 0, "A2": 1, "B1": 0, "B2": 1 },
  "availableSlots": 2,
  "recommendedSlot": "A1"
}
```

Slot values are `0` for available and `1` for occupied. The server merges partial updates into an eight-slot state (A1–B4), recalculates totals, and stores a timestamped snapshot. The server recalculates availability for the full eight-slot layout; therefore, if the camera currently detects only four slots, the other four remain available until their states are supplied.

## Connect the Python detector

The detector currently uses `http://localhost:3000/api/parking`. Keep that address when Python and this backend run on the same laptop. If the backend runs on a different computer, change `localhost` to that computer's LAN IP address. A phone/emulator also needs a reachable host address; `localhost` on the phone refers to the phone itself.

## Flutter app integration

The REST API is now available, but the current Flutter `main.dart` still uses hard-coded demo data. Configure the app to request `GET /api/parking` from a reachable backend URL and refresh periodically before describing the dashboard as live.

## Notes

- Do not expose the API to the public internet without authentication and rate limiting.
- Configure `CORS_ORIGIN` to the exact app origin when deploying a browser-based client.
- This backend stores snapshots; it does not yet ingest ESP32 gate or ultrasonic sensor telemetry.
