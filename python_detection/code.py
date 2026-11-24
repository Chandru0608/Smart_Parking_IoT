
import cv2
import json
import time

# Camera setup
camera = cv2.VideoCapture(1, cv2.CAP_DSHOW)

if not camera.isOpened():
    print("Webcam not detected!")
    exit()

time.sleep(2)

frame = None

print("Waiting for webcam image...")

for i in range(30):
    ret, frame = camera.read()

    if ret and frame is not None:
        break

    time.sleep(0.2)

if frame is None or not ret:
    print("Unable to capture webcam image")
    camera.release()
    exit()

# Live camera preview
print("Press S to capture parking area or Q to quit")

while True:
    ret, live_frame = camera.read()

    if not ret:
        print("Camera capture failed")
        camera.release()
        exit()

    cv2.imshow("Live Parking Camera - Press S to Select", live_frame)

    key = cv2.waitKey(1) & 0xFF

    if key == ord('s'):
        frame = live_frame.copy()
        break

    if key == ord('q'):
        camera.release()
        cv2.destroyAllWindows()
        exit()

camera.release()
cv2.destroyAllWindows()

# Four parking spaces
slot_names = ["A1", "A2", "B1", "B2"]

parking_slots = {}

# Custom rectangle selection
for name in slot_names:

    print("\nSelect parking space:", name)
    print("Draw a rectangle around the parking space.")
    print("You can adjust its size before pressing ENTER.")

    roi = cv2.selectROI(
        "Select " + name,
        frame,
        showCrosshair=True,
        fromCenter=False
    )

    x, y, w, h = roi

    cv2.destroyAllWindows()

    if w == 0 or h == 0:
        print("Selection cancelled. Run again.")
        exit()

    parking_slots[name] = {
        "x": int(x),
        "y": int(y),
        "w": int(w),
        "h": int(h)
    }

    print(
        f"{name} saved: "
        f"x={x}, y={y}, width={w}, height={h}"
    )

# Save coordinates
with open("parking_slots.json", "w") as f:
    json.dump(parking_slots, f, indent=4)

# Display all selected spaces
preview = frame.copy()

for name, box in parking_slots.items():

    x = box["x"]
    y = box["y"]
    w = box["w"]
    h = box["h"]

    cv2.rectangle(
        preview,
        (x, y),
        (x + w, y + h),
        (0, 255, 0),
        2
    )

    cv2.putText(
        preview,
        name,
        (x, max(y - 8, 20)),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.7,
        (0, 255, 0),
        2
    )

cv2.imshow("Four Selected Parking Spaces", preview)

print("\nAll four parking spaces saved successfully!")
print("Created parking_slots.json")

print("Press any key to close preview.")

cv2.waitKey(0)
cv2.destroyAllWindows()
