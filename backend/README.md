# Smart Parking Backend

Node.js, Express and MongoDB REST API for four parking spaces: A1, A2, B1 and B2.

## Setup

Requires Node.js 18+ and a running MongoDB instance or MongoDB Atlas cluster.

From this folder:

```powershell
npm install
Copy-Item .env.example .env
```

Edit `.env` and set `MONGODB_URI`. Keep `.env` private; it is ignored by Git.

Start the API:

```powershell
npm run dev
```

## API

- `GET /api/health` — API and database status.
- `POST /api/parking` — save all four slot states.
- `GET /api/parking` — latest slot state.
- `GET /api/parking/history?limit=20` — recent snapshots (1–100).

POST JSON example:

```json
{
  "slots": { "A1": 0, "A2": 1, "B1": 0, "B2": 1 },
  "availableSlots": 2,
  "recommendedSlot": "A1"
}
```

Use 0 for available and 1 for occupied. The API validates the four slot IDs and calculates counts itself.

## Python detector

Keep `API_URL = "http://localhost:3000/api/parking"` when Python and the backend run on the same computer.

## Flutter networking

- Windows desktop / same computer: `http://localhost:3000`
- Android emulator: `http://10.0.2.2:3000`
- Physical phone: use the laptop's LAN IPv4 address, e.g. `http://192.168.x.x:3000`, and ensure both devices are on the same Wi-Fi. Allow Node.js through Windows Firewall for private networks.

The Flutter dashboard must call `GET /api/parking`; it is not live until that integration is running.
