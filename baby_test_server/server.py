"""
Baby Monitoring Server
=======================
Runs on a Raspberry Pi (one per baby) and exposes sensor/camera data
over HTTP so the Flutter app can poll it through an ngrok tunnel.

-- FOR THE Pi DEVELOPER --
Search this file for  !! CHANGE TO REAL  to find every line you must
replace before deploying. Everything else can stay as-is.

Steps
-----
  1. Fill in BABY_ID and note the NGROK_URL placeholder below.
  2. pip install -r requirements.txt
  3. python server.py
  4. In a separate terminal: ngrok http 5000
  5. Copy the ngrok Forwarding URL and paste it into the monitor_url
     column of this baby's row in Supabase.
  6. When ngrok restarts and gives a new URL, update monitor_url in
     Supabase again. No app rebuild needed.

Endpoints
---------
GET  /baby/<baby_id>/alerts          - latest 10 alerts (newest first)
GET  /baby/<baby_id>/vitals          - heart rate, temperature, SpO2
POST /baby/<baby_id>/alerts/trigger  - inject a test alert (remove on Pi)
GET  /debug/babies                   - list registered IDs  (remove on Pi)
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime, timezone, timedelta
import random
import uuid

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

# !! CHANGE TO REAL: paste the UUID from Supabase (babies table -> id column)
BABY_ID = "PASTE_BABY_UUID_HERE"

# !! CHANGE TO REAL: paste your ngrok Forwarding URL here as a reminder,
# then copy it into monitor_url in Supabase. Not used by the server itself.
NGROK_URL = "https://PASTE_NGROK_URL_HERE"

# ══════════════════════════════════════════════════════════════════════════════

app = Flask(__name__)
CORS(app)

# ── In-memory data store (fake — for development only) ───────────────────────

_alerts: dict[str, list[dict]] = {}
_vitals: dict[str, dict] = {}

# !! CHANGE TO REAL: remove _ALERT_TYPES — on the Pi, detected_object comes
# from your camera/ML model, not a hardcoded list.
_ALERT_TYPES = [
    "Crying detected",
    "Movement detected",
    "Sleeping",
    "Rolling over detected",
    "Unusual sound detected",
    "Activity detected",
]


# ── Initialisation helpers ────────────────────────────────────────────────────

def _init_alerts(baby_id: str) -> list[dict]:
    # !! CHANGE TO REAL: remove this function — on the Pi, alerts come from
    # your camera/detection system, not seeded fake data.
    now = datetime.now(timezone.utc)
    _alerts[baby_id] = [
        {
            "id": str(uuid.uuid4()),
            "baby_id": baby_id,
            "alert_time": (now - timedelta(minutes=i * 7)).isoformat(),
            "detected_object": _ALERT_TYPES[i % len(_ALERT_TYPES)],
            "photo_path": None,
        }
        for i in range(5)
    ]
    return _alerts[baby_id]


def _init_vitals(baby_id: str) -> dict:
    # !! CHANGE TO REAL: remove this function — on the Pi, read initial values
    # directly from your DHT22/sensor on first call instead of hardcoding them.
    _vitals[baby_id] = {
        "heart_rate": 140.0,   # fake starting value
        "temperature": 36.8,   # fake starting value
        "spo2": 98.0,          # fake starting value
    }
    return _vitals[baby_id]


def _get_alerts(baby_id: str) -> list[dict]:
    return _alerts.get(baby_id) or _init_alerts(baby_id)


def _get_vitals(baby_id: str) -> dict:
    return _vitals.get(baby_id) or _init_vitals(baby_id)


# ── Routes ────────────────────────────────────────────────────────────────────

@app.route("/baby/<baby_id>/alerts", methods=["GET"])
def get_alerts(baby_id: str):
    # !! CHANGE TO REAL: replace _get_alerts() with a read from your
    # camera/detection log or database (e.g. a local SQLite file on the Pi).
    return jsonify(_get_alerts(baby_id)[:10])


@app.route("/baby/<baby_id>/alerts/trigger", methods=["POST"])
def trigger_alert(baby_id: str):
    # !! CHANGE TO REAL: remove this entire route from the Pi deployment —
    # it only exists to let you manually inject test alerts during development.
    alerts = _get_alerts(baby_id)
    new_alert = {
        "id": str(uuid.uuid4()),
        "baby_id": baby_id,
        "alert_time": datetime.now(timezone.utc).isoformat(),
        "detected_object": random.choice(_ALERT_TYPES),
        "photo_path": None,
    }
    alerts.insert(0, new_alert)
    print(f"[ALERT] {new_alert['detected_object']} -> baby {baby_id}", flush=True)
    return jsonify(new_alert), 201


@app.route("/baby/<baby_id>/vitals", methods=["GET"])
def get_vitals(baby_id: str):
    v = _get_vitals(baby_id)

    # !! CHANGE TO REAL: replace the three blocks below with actual sensor reads.
    # Example using adafruit-circuitpython-dht:
    #   import adafruit_dht, board
    #   dht = adafruit_dht.DHT22(board.D4)
    #   temperature = dht.temperature
    #   humidity    = dht.humidity       # if you expose humidity too
    # Example heart-rate / SpO2 with MAX30102:
    #   from max30102 import MAX30102
    #   sensor = MAX30102()
    #   heart_rate, spo2 = sensor.read_sequential()

    # !! CHANGE TO REAL: remove drift simulation — read live sensor values instead
    v["heart_rate"] += random.uniform(-2.0, 2.0)
    v["heart_rate"] = max(100.0, min(160.0, v["heart_rate"]))

    # !! CHANGE TO REAL: replace with dht.temperature
    v["temperature"] += random.uniform(-0.05, 0.05)
    v["temperature"] = max(36.5, min(37.5, v["temperature"]))

    # !! CHANGE TO REAL: replace with sensor.spo2
    v["spo2"] += random.uniform(-0.3, 0.3)
    v["spo2"] = max(95.0, min(100.0, v["spo2"]))

    return jsonify({
        "heart_rate": round(v["heart_rate"]),
        "temperature": round(v["temperature"], 1),
        "spo2": round(v["spo2"]),
    })


# ── Debug endpoints (remove from Pi deployment) ───────────────────────────────

# !! CHANGE TO REAL: remove this entire route before deploying to the Pi
@app.route("/debug/babies", methods=["GET"])
def debug_babies():
    return jsonify({
        "registered_ids": list(_alerts.keys()),
        "tip": "Use one of these ids in: POST /baby/<id>/alerts/trigger",
    })


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 55)
    print("  Baby Monitoring Server")
    print("  Listening on http://0.0.0.0:5000")
    print()
    # !! CHANGE TO REAL: update this message for the Pi (remove emulator note)
    print("  Dev: emulator reaches this at http://10.0.2.2:5000")
    print("  Pi:  use your ngrok URL")
    print()
    print("  Press Ctrl+C to stop.")
    print("=" * 55)
    app.run(host="0.0.0.0", port=5000, debug=True)
