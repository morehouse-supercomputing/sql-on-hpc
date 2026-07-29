---
layout: default
title: SQL on HPC
---

# SQL on HPC: Querying Large Databases

This guide walks you through running SQL queries on a large dataset using HPC. The dataset is too big for most laptops — that's the point.

**Dataset:** NYC Yellow Taxi trips (2023) — ~38 million trips, ~9 GB total on disk

**For instructors:** This is a template. Adapt the queries to fit your course. The dataset and setup are ready to go.

---

## Prerequisites

- An HPC account with MFA set up ([MSCF Getting Started guide](https://morehouse-supercomputing.github.io/mscf-getting-started/))
- Access to an HPC system (e.g., Vista, Lonestar6, Stampede3)
- An active allocation

---

## Step 1: Log into the HPC System

```bash
ssh your_username@vista.tacc.utexas.edu
```

> Replace `vista` with your system. See the [Jupyter on HPC guide](https://morehouse-supercomputing.github.io/jupyter-on-hpc/) if you need help with SSH.

---

## Step 2: Clone the Repo

```bash
cd $WORK
git clone https://github.com/morehouse-supercomputing/sql-on-hpc.git
cd sql-on-hpc
mkdir -p data
```

---

## Step 3: Choose How to Get the Database

Now choose one setup path. All three options should leave you with the same file:

```bash
data/nyc_taxi.db
```

### Option A: Copy a pre-built database

Use this option if your instructor has already built the database for you.

If the database is on your computer, upload it from your computer's terminal:

```bash
scp /path/to/nyc_taxi.db your_username@vista.tacc.utexas.edu:'$WORK/sql-on-hpc/data/'
```

Run that command from your own computer, not from inside the SSH session. The quotes keep `$WORK` from expanding on your computer before `scp` connects to the HPC system.

If your instructor staged the database on the HPC system, copy it from the shared location:

```bash
cp /work/10539/ashleyscruse/vista/gosha-sql-assignment/data/nyc_taxi.db data/
```

This is the fastest path. You skip the data build and go straight to querying.

### Option B: Run the setup script

Use this option if you want the repo to download the raw files and build the database for you:

```bash
bash scripts/setup_data.sh
```

This downloads 12 months of NYC taxi data (~3 GB), loads it into a SQLite database (~6 GB), and creates indexes. About ~9 GB total disk. Takes 10-15 minutes.

### Option C: Write your own setup script

Use this option if your assignment asks you to build the database yourself. Your script should:

1. Download or read the 2023 NYC Yellow Taxi Parquet files.
2. Select and rename the columns used in this guide.
3. Load the rows into a SQLite table named `trips`.
4. Create the `zones` lookup table.
5. Save the finished database as `data/nyc_taxi.db`.

You can inspect `scripts/setup_data.sh` as a reference, but your script does not have to match it exactly.

> **Instructor tip:** These are three setup paths to the same assignment. For a live class, the pre-built database is the safest default. The setup script and custom-script paths are useful when you want students to see or control how the database was built.

---

## Step 4: Open the Database

### From the command line

```bash
sqlite3 data/nyc_taxi.db
```

You're now in an interactive SQL shell. Try:

```sql
SELECT COUNT(*) FROM trips;
```

You should see ~38 million rows.

### From a Jupyter notebook

If you're using Jupyter on HPC (see the [Jupyter guide](https://morehouse-supercomputing.github.io/jupyter-on-hpc/)):

```python
import sqlite3
conn = sqlite3.connect('data/nyc_taxi.db')
cursor = conn.cursor()

cursor.execute("SELECT COUNT(*) FROM trips")
print(cursor.fetchone()[0])
```

---

## The Database

### Tables

**trips** — ~38 million rows

| Column | Type | Description |
|--------|------|-------------|
| pickup_time | TEXT | Pickup date and time |
| dropoff_time | TEXT | Dropoff date and time |
| passengers | INTEGER | Number of passengers |
| distance_miles | REAL | Trip distance |
| pickup_zone_id | INTEGER | Pickup location (zone ID) |
| dropoff_zone_id | INTEGER | Dropoff location (zone ID) |
| fare | REAL | Base fare amount |
| tip | REAL | Tip amount |
| total | REAL | Total charged |
| payment_type | INTEGER | 1=Credit card, 2=Cash, 3=No charge, 4=Dispute |

**zones** — 70 rows (Manhattan zones with names)

| Column | Type | Description |
|--------|------|-------------|
| zone_id | INTEGER | Zone ID (matches pickup/dropoff zone IDs) |
| zone_name | TEXT | Neighborhood name |

### Indexes

Indexes exist on: `pickup_time`, `pickup_zone_id`, `dropoff_zone_id`, `distance_miles`, `fare`

---

## Example Queries

### Basic: Counting and Filtering

**How many trips are in the database?**

```sql
SELECT COUNT(*) FROM trips;
```

**How many trips had more than 4 passengers?**

```sql
SELECT COUNT(*) FROM trips WHERE passengers > 4;
```

**What's the average fare?**

```sql
SELECT ROUND(AVG(fare), 2) AS avg_fare FROM trips;
```

**What's the longest trip by distance?**

```sql
SELECT distance_miles, fare, total, pickup_time
FROM trips
ORDER BY distance_miles DESC
LIMIT 10;
```

---

### Intermediate: Aggregation and Grouping

**Average fare by passenger count:**

```sql
SELECT passengers,
       COUNT(*) AS num_trips,
       ROUND(AVG(fare), 2) AS avg_fare,
       ROUND(AVG(tip), 2) AS avg_tip
FROM trips
WHERE passengers > 0
GROUP BY passengers
ORDER BY passengers;
```

**Trips per month:**

```sql
SELECT SUBSTR(pickup_time, 1, 7) AS month,
       COUNT(*) AS num_trips,
       ROUND(SUM(total), 2) AS total_revenue
FROM trips
GROUP BY month
ORDER BY month;
```

**Busiest pickup zones (top 10):**

```sql
SELECT pickup_zone_id,
       COUNT(*) AS num_trips
FROM trips
GROUP BY pickup_zone_id
ORDER BY num_trips DESC
LIMIT 10;
```

---

### Advanced: Joins, Subqueries, and Window Functions

**Busiest zones with names (JOIN):**

```sql
SELECT z.zone_name,
       COUNT(*) AS num_trips,
       ROUND(AVG(t.fare), 2) AS avg_fare
FROM trips t
JOIN zones z ON t.pickup_zone_id = z.zone_id
GROUP BY z.zone_name
ORDER BY num_trips DESC
LIMIT 10;
```

**Which zones have the highest average tips? (JOIN + GROUP BY + ORDER)**

```sql
SELECT z.zone_name,
       COUNT(*) AS num_trips,
       ROUND(AVG(t.tip), 2) AS avg_tip,
       ROUND(AVG(t.fare), 2) AS avg_fare
FROM trips t
JOIN zones z ON t.pickup_zone_id = z.zone_id
GROUP BY z.zone_name
HAVING num_trips > 10000
ORDER BY avg_tip DESC
LIMIT 10;
```

**Airport trips vs non-airport trips (subquery):**

```sql
SELECT
    CASE
        WHEN pickup_zone_id IN (132, 138, 1) THEN 'Airport'
        ELSE 'Non-Airport'
    END AS trip_type,
    COUNT(*) AS num_trips,
    ROUND(AVG(fare), 2) AS avg_fare,
    ROUND(AVG(distance_miles), 2) AS avg_distance,
    ROUND(AVG(tip), 2) AS avg_tip
FROM trips
GROUP BY trip_type;
```

**Credit card vs cash tipping behavior:**

```sql
SELECT
    CASE payment_type
        WHEN 1 THEN 'Credit Card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No Charge'
        WHEN 4 THEN 'Dispute'
        ELSE 'Other'
    END AS payment_method,
    COUNT(*) AS num_trips,
    ROUND(AVG(tip), 2) AS avg_tip,
    ROUND(AVG(fare), 2) AS avg_fare,
    ROUND(AVG(tip) / NULLIF(AVG(fare), 0) * 100, 1) AS tip_pct
FROM trips
GROUP BY payment_type
ORDER BY num_trips DESC;
```

**Hourly trip patterns (time extraction):**

```sql
SELECT CAST(SUBSTR(pickup_time, 12, 2) AS INTEGER) AS hour_of_day,
       COUNT(*) AS num_trips,
       ROUND(AVG(fare), 2) AS avg_fare
FROM trips
WHERE pickup_time IS NOT NULL
GROUP BY hour_of_day
ORDER BY hour_of_day;
```

---

## Why HPC?

This database has ~38 million rows and takes up ~9 GB on disk. Here's why you'd want HPC for this:

| | Your Laptop | HPC Compute Node |
|---|---|---|
| RAM | 8-16 GB | 128-223 GB |
| Disk | Limited SSD | 1 TB+ on $WORK |
| Full table scan on 38M rows | Slow, might swap to disk | Fast, fits in memory |
| Multiple queries at once | Bogs down | Plenty of headroom |

A query that scans all 38 million rows needs to load the database into memory. At ~9 GB, a laptop with 8 GB of RAM can't hold it without swapping to disk. On HPC with 223 GB of RAM, 9 GB is a rounding error.

> **For instructors:** The real teaching moment is when a student runs a query on their laptop and it takes 30 seconds, then runs the same query on HPC and it takes 2 seconds. That's the "aha."

---

## Tips for Instructors

**Before class:**
- Run `setup_data.sh` ahead of time so students don't wait 15 minutes
- Consider cloning to a shared location on `$WORK` if all students are on the same allocation
- Test your custom queries on the actual data

**Adapting for your course:**
- The example queries cover SELECT, WHERE, GROUP BY, JOIN, HAVING, CASE, subqueries, and time extraction
- Add your own queries to match your syllabus
- The `zones` table is intentionally small (70 rows) to make JOINs fast for teaching
- Payment type codes (1-4) are good for CASE WHEN exercises

**Assessment ideas:**
- "Write a query that finds the average tip percentage by zone for trips over 5 miles"
- "Which hour of the day has the most expensive average fare? Why might that be?"
- "Compare weekend vs weekday trip volumes" (requires date extraction)

---

## Troubleshooting

**"sqlite3: command not found"**
- SQLite is usually available system-wide on HPC. Try `/usr/bin/sqlite3`. If not, run `module load gcc/13.2.0` then `module load sqlite`.

**"setup_data.sh is taking forever"**
- The download is ~3 GB. On HPC it should take 5-10 minutes. Make sure you're on the login node (not a compute node) for better network access.

**"database is locked"**
- Only one process can write to SQLite at a time. If the setup script failed partway, delete the database and re-run: `rm data/nyc_taxi.db && bash scripts/setup_data.sh`

**"disk quota exceeded"**
- You might be in `$HOME` (10 GB limit). Make sure you cloned into `$WORK`.

---

## Quick Reference

| Task | Command |
|------|---------|
| Open database | `sqlite3 data/nyc_taxi.db` |
| Count rows | `SELECT COUNT(*) FROM trips;` |
| Show tables | `.tables` |
| Show columns | `.schema trips` |
| Pretty output | `.mode column` then `.headers on` |
| Export to CSV | `.mode csv` then `.output results.csv` then run query |
| Exit SQLite | `.quit` |
