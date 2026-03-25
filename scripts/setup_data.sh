#!/bin/bash
# Download NYC Yellow Taxi trip data and load into SQLite
# Downloads ~3GB of Parquet files, creates a ~6GB SQLite database
# Total: ~20 million trips from 2023

set -e

DATA_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )/data"
DB_PATH="$DATA_DIR/nyc_taxi.db"

mkdir -p "$DATA_DIR"

if [ -f "$DB_PATH" ]; then
    echo "Database already exists at $DB_PATH"
    echo "To rebuild, delete it first: rm $DB_PATH"
    exit 0
fi

echo "==================================="
echo " NYC Taxi Data Setup"
echo "==================================="
echo ""
echo "This will:"
echo "  1. Download 2023 Yellow Taxi trip data (~3 GB)"
echo "  2. Load it into a SQLite database (~6 GB)"
echo "  3. Create indexes for fast queries"
echo ""
echo "Estimated time: 10-15 minutes"
echo "Estimated disk: ~9 GB in $DATA_DIR"
echo ""

# Download parquet files for each month of 2023
MONTHS="01 02 03 04 05 06 07 08 09 10 11 12"
BASE_URL="https://d37ci6vzurychx.cloudfront.net/trip-data"

for month in $MONTHS; do
    FILE="yellow_tripdata_2023-${month}.parquet"
    URL="${BASE_URL}/${FILE}"
    DEST="$DATA_DIR/$FILE"

    if [ -f "$DEST" ]; then
        echo "Already downloaded: $FILE"
    else
        echo "Downloading: $FILE ..."
        wget -q -O "$DEST" "$URL"
        echo "  Done."
    fi
done

echo ""
echo "All files downloaded. Loading into SQLite..."
echo ""

# Load into SQLite using Python (parquet -> sqlite)
python3 << 'PYEOF'
import sqlite3
import os
import glob

try:
    import pyarrow.parquet as pq
except ImportError:
    print("Installing pyarrow...")
    os.system("pip install --user pyarrow")
    import pyarrow.parquet as pq

try:
    import pandas as pd
except ImportError:
    print("Installing pandas...")
    os.system("pip install --user pandas")
    import pandas as pd

data_dir = os.environ.get("DATA_DIR", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data"))
# Use the DATA_DIR from bash
import sys
data_dir = sys.argv[1] if len(sys.argv) > 1 else "data"

db_path = os.path.join(data_dir, "nyc_taxi.db")
conn = sqlite3.connect(db_path)

files = sorted(glob.glob(os.path.join(data_dir, "yellow_tripdata_2023-*.parquet")))
total = len(files)

for i, f in enumerate(files, 1):
    month = os.path.basename(f).split("-")[1].replace(".parquet", "")
    print(f"  [{i}/{total}] Loading {month}...", end=" ", flush=True)

    df = pd.read_parquet(f)

    # Keep useful columns and rename for simplicity
    cols = {
        "tpep_pickup_datetime": "pickup_time",
        "tpep_dropoff_datetime": "dropoff_time",
        "passenger_count": "passengers",
        "trip_distance": "distance_miles",
        "PULocationID": "pickup_zone_id",
        "DOLocationID": "dropoff_zone_id",
        "fare_amount": "fare",
        "tip_amount": "tip",
        "total_amount": "total",
        "payment_type": "payment_type",
    }

    df = df[[c for c in cols.keys() if c in df.columns]].rename(columns=cols)

    # Append to trips table
    df.to_sql("trips", conn, if_exists="append", index=False)
    print(f"{len(df):,} rows")

# Create indexes
print("")
print("Creating indexes (this speeds up queries)...")
conn.execute("CREATE INDEX IF NOT EXISTS idx_pickup_time ON trips(pickup_time);")
conn.execute("CREATE INDEX IF NOT EXISTS idx_pickup_zone ON trips(pickup_zone_id);")
conn.execute("CREATE INDEX IF NOT EXISTS idx_dropoff_zone ON trips(dropoff_zone_id);")
conn.execute("CREATE INDEX IF NOT EXISTS idx_distance ON trips(distance_miles);")
conn.execute("CREATE INDEX IF NOT EXISTS idx_fare ON trips(fare);")

# Create a zone lookup table
print("Creating zone lookup table...")
zones = {
    1: "Newark Airport", 2: "Jamaica Bay", 4: "Alphabet City",
    7: "Astoria", 12: "Battery Park", 13: "Battery Park City",
    24: "Bloomingdale", 36: "Brooklyn Heights", 37: "Brownsville",
    41: "Central Harlem", 42: "Central Harlem North", 43: "Central Park",
    45: "Chinatown", 48: "Clinton East", 50: "Clinton West",
    68: "East Chelsea", 74: "East Harlem North", 75: "East Harlem South",
    79: "East Village", 87: "Financial District North", 88: "Financial District South",
    90: "Flatiron", 100: "Garment District", 107: "Gramercy",
    113: "Greenwich Village North", 114: "Greenwich Village South",
    125: "Hudson Sq", 127: "Inwood", 128: "Inwood Hill Park",
    137: "Kips Bay", 140: "Lenox Hill East", 141: "Lenox Hill West",
    142: "Lincoln Square East", 143: "Lincoln Square West",
    144: "Little Italy/NoLiTa", 148: "Lower East Side",
    151: "Manhattan Valley", 152: "Manhattanville",
    153: "Marble Hill", 158: "Meatpacking/West Village West",
    161: "Midtown Center", 162: "Midtown East", 163: "Midtown North",
    164: "Midtown South", 166: "Morningside Heights",
    170: "Murray Hill", 186: "Penn Station/Madison Sq West",
    194: "Randalls Island", 202: "Roosevelt Island",
    209: "Seaport", 211: "SoHo", 224: "Stuy Town/PCV",
    229: "Sutton Place/Turtle Bay North", 230: "Sutton Place/Turtle Bay South",
    231: "Times Sq/Theatre District", 232: "TriBeCa/Civic Center",
    233: "Two Bridges/Seward Park", 234: "UN/Turtle Bay South",
    236: "Upper East Side North", 237: "Upper East Side South",
    238: "Upper West Side North", 239: "Upper West Side South",
    243: "Washington Heights North", 244: "Washington Heights South",
    246: "West Chelsea/Hudson Yards", 249: "West Village",
    261: "World Trade Center", 262: "Yorkville East", 263: "Yorkville West",
    132: "JFK Airport", 138: "LaGuardia Airport",
}

conn.execute("CREATE TABLE IF NOT EXISTS zones (zone_id INTEGER PRIMARY KEY, zone_name TEXT);")
conn.executemany("INSERT OR IGNORE INTO zones VALUES (?, ?)", zones.items())

conn.commit()

# Print summary
cursor = conn.execute("SELECT COUNT(*) FROM trips")
total_rows = cursor.fetchone()[0]
print(f"")
print(f"=================================")
print(f" Setup Complete!")
print(f" Database: {db_path}")
print(f" Total trips: {total_rows:,}")
print(f" Tables: trips, zones")
print(f"=================================")

conn.close()
PYEOF

echo ""
echo "You can now query the database:"
echo "  sqlite3 $DB_PATH"
echo ""
echo "Or from Python:"
echo "  import sqlite3"
echo "  conn = sqlite3.connect('$DB_PATH')"