---
layout: default
title: SQL on HPC
---

# SQL on HPC: Querying Large Databases

This guide walks you through running SQL queries on a large dataset using HPC. The dataset is too big for most laptops — that's the point.

**Dataset:** NYC Yellow Taxi trips (2023) — ~38 million trips, ~9 GB total on disk

---

## Prerequisites

- An HPC account with MFA set up ([MSF Getting Started guide](https://morehouse-supercomputing.github.io/mscf-getting-started/))
- Membership on the allocation your instructor is using
- **Pre-work:** log in at `accounts.tacc.utexas.edu`, set up MFA with an authenticator app (Okta Verify or Google Authenticator, not SMS), and submit a screenshot of your account page

---

## Step 1: Open a Terminal in TAP

1. Go to the [TACC Analysis Portal (TAP)](https://tap.tacc.utexas.edu) and log in with your TACC username, password, and MFA code.
2. Start a **Jupyter** session on **Vista**, using the project and reservation your instructor gives you.
3. When the session is ready, click **Connect**.
4. In Jupyter, open a **Terminal** from the Launcher.

You are now on a Vista compute node. No SSH needed.

---

## Step 2: Open the Database

The database is already built and staged on Vista. Open it read-only, in one line:

```bash
sqlite3 -readonly /work/10539/ashleyscruse/vista/gosha-sql-assignment/data/nyc_taxi.db
```

You're now in an interactive SQL shell. Try:

```sql
SELECT COUNT(*) FROM trips;
```

You should see ~38 million rows.

The database never touches your laptop. It lives on the HPC system and stays there, which is the whole reason you are working on the HPC system in the first place.

### From a Jupyter notebook instead

In the same TAP session, open a new Python notebook from the Launcher:

```python
import sqlite3
conn = sqlite3.connect('file:/work/10539/ashleyscruse/vista/gosha-sql-assignment/data/nyc_taxi.db?mode=ro', uri=True)
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

---

## Troubleshooting

**"sqlite3: command not found"**
- SQLite is usually available system-wide on HPC. Try `/usr/bin/sqlite3`. If not, run `module load gcc/13.2.0` then `module load sqlite`.

**"unable to open database file"**
- Check the path for typos. If it is correct, tell your instructor; your account may not be on the allocation yet.

**"attempt to write a readonly database"**
- Expected. The staged database is shared and read-only, so `SELECT` queries work and `INSERT`, `UPDATE`, and `CREATE` do not.

---

## Quick Reference

| Task | Command |
|------|---------|
| Open database | `sqlite3 -readonly /work/10539/ashleyscruse/vista/gosha-sql-assignment/data/nyc_taxi.db` |
| Count rows | `SELECT COUNT(*) FROM trips;` |
| Show tables | `.tables` |
| Show columns | `.schema trips` |
| Pretty output | `.mode column` then `.headers on` |
| Export to CSV | `.mode csv` then `.output results.csv` then run query |
| Exit SQLite | `.quit` |
