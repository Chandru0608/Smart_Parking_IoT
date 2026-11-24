
import cv2
import json
import numpy as np
import requests
import time
import threading
from queue import Queue, Empty

# ==================================================
# CONFIGURATION
# ==================================================

API_URL = "http://localhost:3000/api/parking"

CAMERA_INDEX = 1

CAMERA_WIDTH = 640
CAMERA_HEIGHT = 480

DETECTION_INTERVAL = 0.3
UPDATE_INTERVAL = 3

SLOT_PRIORITY = ["A1", "A2", "B1", "B2"]

# Detection thresholds
COLOUR_SATURATION = 75
COLOUR_BRIGHTNESS = 45

NEUTRAL_SATURATION = 85
NEUTRAL_BRIGHTNESS = 145

OCCUPANCY_THRESHOLD = 0.08

# ==================================================
# LOAD PARKING SLOT COORDINATES
# ==================================================

try:
    with open("parking_slots.json", "r") as file:
        slots = json.load(file)

except FileNotFoundError:
    print("ERROR: parking_slots.json not found!")
    exit()

if set(slots.keys()) != set(SLOT_PRIORITY):
    print("ERROR: Expected exactly these four slots:")
    print(SLOT_PRIORITY)
    exit()

# ==================================================
# CAMERA INITIALIZATION
# ==================================================

camera = cv2.VideoCapture(CAMERA_INDEX, cv2.CAP_DSHOW)

camera.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
camera.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)
camera.set(cv2.CAP_PROP_BUFFERSIZE, 1)

if not camera.isOpened():
    print("ERROR: Webcam not detected!")
    exit()

print("======================================")
print("      SMART PARKING SYSTEM")
print("======================================")
print("Camera connected")
print("Parking slots: A1, A2, B1, B2")
print("White and silver detection enabled")
print("MongoDB backend:", API_URL)
print("Press Q to quit")
print("======================================")

# ==================================================
# BACKGROUND API WORKER
# ==================================================

api_queue = Queue(maxsize=1)


def api_worker():

    session = requests.Session()

    while True:

        payload = api_queue.get()

        if payload is None:
            api_queue.task_done()
            break

        try:

            response = session.post(
                API_URL,
                json=payload,
                timeout=2
            )

            response.raise_for_status()

            print(
                "BACKEND UPDATED | Available:",
                payload["availableSlots"],
                "| Recommended:",
                payload["recommendedSlot"]
            )

        except requests.RequestException as error:

            print("BACKEND ERROR:", error)

        finally:
            api_queue.task_done()

    session.close()


worker = threading.Thread(
    target=api_worker,
    daemon=True
)

worker.start()

# ==================================================
# DETECTION VARIABLES
# ==================================================

results = {
    name: 0 for name in SLOT_PRIORITY
}

detection_percentages = {
    name: 0.0 for name in SLOT_PRIORITY
}

available = 4
occupied = 0
recommended = "A1"

last_detection = 0
last_update = 0

# ==================================================
# MAIN DETECTION FUNCTION
# ==================================================

def detect_vehicle(roi):

    hsv = cv2.cvtColor(
        roi,
        cv2.COLOR_BGR2HSV
    )

    saturation = hsv[:, :, 1]
    brightness = hsv[:, :, 2]

    # Detect colourful vehicles
    colourful = (
        (saturation > COLOUR_SATURATION) &
        (brightness > COLOUR_BRIGHTNESS)
    )

    # Detect white and silver vehicles
    bright_neutral = (
        (saturation < NEUTRAL_SATURATION) &
        (brightness > NEUTRAL_BRIGHTNESS)
    )

    # Combine both detection methods
    vehicle_pixels = colourful | bright_neutral

    vehicle_ratio = (
        np.count_nonzero(vehicle_pixels) /
        vehicle_pixels.size
    )

    is_occupied = (
        vehicle_ratio > OCCUPANCY_THRESHOLD
    )

    return is_occupied, vehicle_ratio


# ==================================================
# MAIN LOOP
# ==================================================

try:

    while True:

        ret, frame = camera.read()

        if not ret:
            print("ERROR: Camera frame failed")
            break

        current_time = time.monotonic()

        # ------------------------------------------
        # PARKING DETECTION
        # ------------------------------------------

        if current_time - last_detection >= DETECTION_INTERVAL:

            for name in SLOT_PRIORITY:

                box = slots[name]

                x = box["x"]
                y = box["y"]
                w = box["w"]
                h = box["h"]

                # Validate coordinates
                if (
                    x < 0 or y < 0 or
                    x + w > frame.shape[1] or
                    y + h > frame.shape[0]
                ):
                    print("Invalid ROI:", name)
                    continue

                # Remove ROI boundary margins
                margin_x = max(2, int(w * 0.08))
                margin_y = max(2, int(h * 0.08))

                roi = frame[
                    y + margin_y:y + h - margin_y,
                    x + margin_x:x + w - margin_x
                ]

                if roi.size == 0:
                    continue

                # Detect colourful and neutral vehicles
                is_occupied, ratio = detect_vehicle(roi)

                results[name] = int(is_occupied)

                detection_percentages[name] = ratio * 100

            last_detection = current_time

            # Calculate parking statistics
            occupied = sum(results.values())
            available = len(SLOT_PRIORITY) - occupied

            # Recommend first available slot
            recommended = next(
                (
                    name for name in SLOT_PRIORITY
                    if results[name] == 0
                ),
                "PARKING FULL"
            )

        # ------------------------------------------
        # DISPLAY PARKING SLOT STATUS
        # ------------------------------------------

        for name in SLOT_PRIORITY:

            box = slots[name]

            x = box["x"]
            y = box["y"]
            w = box["w"]
            h = box["h"]

            is_occupied = results[name] == 1

            colour = (
                (0, 0, 255) if is_occupied
                else (0, 255, 0)
            )

            status = (
                "OCCUPIED" if is_occupied
                else "AVAILABLE"
            )

            # Draw parking boundary
            cv2.rectangle(
                frame,
                (x, y),
                (x + w, y + h),
                colour,
                2
            )

            # Display status
            cv2.putText(
                frame,
                f"{name}: {status}",
                (x, max(y - 8, 20)),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.48,
                colour,
                2
            )

            # Display detection percentage
            cv2.putText(
                frame,
                f"Detection: {detection_percentages[name]:.1f}%",
                (x + 3, y + h - 8),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.4,
                (255, 255, 0),
                1
            )

        # ------------------------------------------
        # DISPLAY TOTAL STATISTICS
        # ------------------------------------------

        cv2.putText(
            frame,
            f"Available: {available}",
            (15, 30),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (0, 255, 0),
            2
        )

        cv2.putText(
            frame,
            f"Occupied: {occupied}",
            (15, 60),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (0, 0, 255),
            2
        )

        cv2.putText(
            frame,
            f"Recommended: {recommended}",
            (15, 90),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (255, 255, 0),
            2
        )

        # ------------------------------------------
        # SEND DATA TO NODE.JS / MONGODB
        # ------------------------------------------

        if current_time - last_update >= UPDATE_INTERVAL:

            payload = {
                "slots": results.copy(),
                "availableSlots": available,
                "recommendedSlot": recommended
            }

            # Keep only the latest pending update
            if api_queue.full():

                try:
                    api_queue.get_nowait()
                    api_queue.task_done()

                except Empty:
                    pass

            try:
                api_queue.put_nowait(payload)

            except Exception as error:
                print("Queue error:", error)

            last_update = current_time

        # ------------------------------------------
        # CAMERA PREVIEW
        # ------------------------------------------

        cv2.imshow(
            "Smart Parking - Vehicle Detection",
            frame
        )

        key = cv2.waitKey(1) & 0xFF

        if key == ord("q"):
            break

finally:

    camera.release()

    cv2.destroyAllWindows()

    # Stop API worker
    api_queue.put(None)

    worker.join(timeout=3)

    print("======================================")
    print("SMART PARKING SYSTEM STOPPED")
    print("======================================")
