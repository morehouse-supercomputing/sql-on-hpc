---
name: SQL on HPC (Guest Lecture + Template)
project_type: workshop
domain:
  - career
status: done
started: 2026-03-15
target: 2026-04-27
entities:
  - "[[morehouse]]"
  - "[[mscf]]"
  - "[[tacc]]"
people:
  - "[[scruse-ashley]]"
program: "[[mscf]]"
tags:
  - workshop
  - module
  - guest-lecture
  - template
  - teaching
  - mscf
  - morehouse
  - sql
  - hpc
  - done
  - reusable
---
# SQL on HPC (Guest Lecture + Template)

Reusable SQL-on-HPC template (NYC Taxi dataset, ~38M rows on Vista) + guest lecture delivered 2026-04-27 for Kenneth Scoti's database systems course.

**Status:** Done (guest lecture delivered; template ongoing for instructor adoption)

## Quick links
- Lead: [[scruse-ashley]]
- Owner: [[mscf]]
- Public URL: morehouse-supercomputing.github.io/sql-on-hpc
- Source repo: github.com/morehouse-supercomputing/sql-on-hpc

## Tasks
- [x] Build SQL on HPC template repo ✅ 2026-04-01
- [x] Publish public guide ✅ 2026-04-01
- [x] Build lesson plan and runbook ✅ 2026-04-20
- [x] Build SQL Slides / Guest Lecture Materials ✅ 2026-04-26
- [x] Deliver guest lecture for Kenneth Scoti ✅ 2026-04-27

## Overview

### Goal
Deliver SQL on HPC as a guest lecture (April 27, 2026) for Kenneth Scoti's database systems course, using the reusable NYC Taxi dataset template hosted by MSCF. Maintain the template so other instructors can adopt it.

### Why this matters
The April 27 delivery validated the SQL-on-HPC template against a live database systems course. It also produced the materials package (slides, lesson plan, runbook) that any instructor can pick up. The template uses the NYC Taxi dataset (~38M trips, ~9 GB), which is large enough to be a real HPC exercise but small enough to fit in a single class period. Sets up summer 2026 NAIRR Accelerator instructors to adopt it without rebuilding.

### Template content
- Step-by-step guide for running SQLite on HPC
- Setup script: downloads and loads the NYC Taxi dataset (~38M trips, ~9 GB)
- Example queries (basic to advanced)

### Next action
Close out the April 27 lecture instance. Template improvements for summer 2026 NAIRR Accelerator adoption tracked separately in the source ROADMAP.

## Live dashboard

### Open tasks
```dataview
TASK
FROM "morehouse/workshops/modules/sql-on-hpc"
WHERE !completed AND (
  contains(file.path, "sql-on-hpc.md") OR
  contains(string(tags), "#task")
)
GROUP BY file.link
SORT due ASC
```

### Recently completed
```dataview
TASK
FROM "morehouse/workshops/modules/sql-on-hpc"
WHERE completed AND (
  contains(file.path, "sql-on-hpc.md") OR
  contains(string(tags), "#task")
)
GROUP BY file.link
SORT completion DESC
LIMIT 5
```
