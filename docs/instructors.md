---
layout: default
title: "SQL on HPC: Instructor Guide"
---

# SQL on HPC: Instructor Guide

This page is for whoever is leading or TAing the workshop. Students follow the [student guide](./). The slides are shared separately.

The workshop is a template. Adapt the queries to fit the course. The dataset and setup are ready to go.

---

## Before Class

- **Reservation.** Confirm the Vista reservation name for the class date and give it to students with the project name.
- **Test from a student account.** Log in to TAP, start a Jupyter session on Vista, open a Terminal, and run:

  ```bash
  sqlite3 -readonly /work/10539/ashleyscruse/vista/gosha-sql-assignment/data/nyc_taxi.db
  ```

  Then `SELECT COUNT(*) FROM trips;` should return ~38 million.
- **Student logins.** Students should log in to TAP and finish MFA setup before class, so class time goes to the queries.
- **Custom queries.** If you add any, test them on the actual data first.

---

## The Database

Students open a shared, pre-built copy read-only:

```
/work/10539/ashleyscruse/vista/gosha-sql-assignment/data/nyc_taxi.db
```

It is ~38 million NYC Yellow Taxi trips from 2023, ~9 GB on disk, with indexes on `pickup_time`, `pickup_zone_id`, `dropoff_zone_id`, `distance_miles`, and `fare`. Read-only means `SELECT` works and `INSERT`, `UPDATE`, and `CREATE` do not.

**Building your own copy.** Clone this repo into `$WORK` and run `bash scripts/setup_data.sh`. It downloads 12 months of data (~3 GB), loads it into SQLite, and creates indexes, about 10-15 minutes and ~9 GB. Do this before class, not during it.

**For an advanced class,** have students write their own build script instead of running `scripts/setup_data.sh`. It should read the 2023 NYC Yellow Taxi Parquet files, select and rename the columns used in the guide, load the rows into a `trips` table, create the `zones` lookup table, and save the result as a SQLite database. `scripts/setup_data.sh` works as a reference; their version does not have to match it.

---

## The Teaching Moment

The real teaching moment is when a student runs a query on their laptop and it takes 30 seconds, then runs the same query on HPC and it takes 2 seconds. That's the "aha."

---

## Adapting the Workshop

**Adapting for your course:**
- The example queries cover SELECT, WHERE, GROUP BY, JOIN, HAVING, CASE, subqueries, and time extraction
- Add your own queries to match your syllabus
- The `zones` table is intentionally small (70 rows) to make JOINs fast for teaching
- Payment type codes (1-4) are good for CASE WHEN exercises

**Assessment ideas:**
- "Write a query that finds the average tip percentage by zone for trips over 5 miles"
- "Which hour of the day has the most expensive average fare? Why might that be?"
- "Compare weekend vs weekday trip volumes" (requires date extraction)
