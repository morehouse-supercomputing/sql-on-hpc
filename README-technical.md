# SQL on HPC

A template for running SQL queries on large datasets using HPC systems. Designed for database systems courses.

## Guide

**[Read the guide](https://morehouse-supercomputing.github.io/sql-on-hpc/)**

## What's Inside

- Step-by-step guide for running SQLite on HPC
- Setup script that downloads and loads the NYC Taxi dataset (~38 million trips, ~9 GB)
- Example queries from basic to advanced
- Ready for any professor to adapt for their course

## Quick Start (on HPC)

```bash
cd $WORK
git clone https://github.com/morehouse-supercomputing/sql-on-hpc.git
cd sql-on-hpc
bash scripts/setup_data.sh
```

## Maintained By

Morehouse Supercomputing Facility