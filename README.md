# SQL on HPC

A template for running SQL queries on large datasets using TACC's HPC systems. Designed for database systems courses.

## Guide

**[Read the guide](https://ashleyscruse.github.io/sql-on-tacc/)**

## What's Inside

- Step-by-step guide for running SQLite on TACC
- Setup script that downloads and loads the NYC Taxi dataset (~20 million trips)
- Example queries from basic to advanced
- Ready for any professor to adapt for their course

## Quick Start (on TACC)

```bash
cd $WORK
git clone https://github.com/ashleyscruse/sql-on-tacc.git
cd sql-on-tacc
bash scripts/setup_data.sh
```

## Maintained By

Morehouse Supercomputing Facility