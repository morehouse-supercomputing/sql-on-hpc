---
layout: default
title: SQL on HPC
---

# SQL on HPC: Querying Large Databases on TACC

This guide walks you through running SQL queries on a large dataset using TACC's HPC systems. The dataset is too big for most laptops — that's the point.

**Dataset:** NYC Yellow Taxi trips (2023) — ~20 million trips, ~6 GB database

**For instructors:** This is a template. Adapt the queries to fit your course. The dataset and setup are ready to go.

---

## Prerequisites

- A TACC account with MFA set up ([MSF Getting Started guide](https://ashleyscruse.github.io/msf-getting-started/))
- Access to a TACC system (Vista, Lonestar6, Stampede3, etc.)
- An active allocation

---

## Step 1: Log into TACC

```bash
ssh your_username@vista.tacc.utexas.edu
```

> Replace `vista` with your system. See the [Jupyter on TACC guide](https://ashleyscruse.github.io/jupyter-on-tacc/) if you need help with SSH.

---

## Step 2: Clone the Repo and Set Up the Data

```bash
cd $WORK
git clone https://github.com/ashleyscruse/sql-on-tacc.git
cd sql-on-tacc
bash scripts/setup_data.sh
```

This downloads 12 months of NYC taxi data and loads it into a SQLite database. Takes about 10-15 minutes and uses ~9 GB of disk.

> **Instructor tip:** Run this before class so students don't wait. You can clone once to a shared directory, or have each student run it on their own `$WORK`.

---

## Step 3: Open the Database

### From the command line

```bash
sqlite3 data/nyc_taxi.db
```

You're now in an interactive SQL shell. Try:

```sql
SELECT COUNT(*) FROM trips;
```

You should see ~20 million rows.

### From a Jupyter notebook

If you're using Jupyter on TACC (see the [Jupyter guide](https://ashleyscruse.github.io/jupyter-on-tacc/)):

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

**trips** — ~20 million rows

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

This database has ~20 million rows and takes up ~6 GB on disk. Here's why you'd want HPC for this:

| | Your Laptop | TACC Compute Node |
|---|---|---|
| RAM | 8-16 GB | 128-223 GB |
| Disk | Limited SSD | 1 TB+ on $WORK |
| Full table scan on 20M rows | Slow, might swap to disk | Fast, fits in memory |
| Multiple queries at once | Bogs down | Plenty of headroom |

A query that scans all 20 million rows needs to read ~6 GB. If your laptop has 8 GB of RAM and the OS is using 4 GB, there's not much room. On TACC, 6 GB is a rounding error.

> **For instructors:** The real teaching moment is when a student runs a query on their laptop and it takes 30 seconds, then runs the same query on TACC and it takes 2 seconds. That's the "aha."

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
- SQLite is usually available system-wide on TACC. Try `/usr/bin/sqlite3`. If not, run `module load gcc/13.2.0` then `module load sqlite`.

**"setup_data.sh is taking forever"**
- The download is ~3 GB. On TACC it should take 5-10 minutes. Make sure you're on the login node (not a compute node) for better network access.

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