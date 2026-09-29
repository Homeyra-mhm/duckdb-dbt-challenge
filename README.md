<img src="https://assets.website-files.com/61a888508b7cccb7485cdac2/61b31d9009792071f950394b_logo_dscovr.svg">

# Data Engineer: DuckDB & DBT - Dynamic Data Modeling Challenge

## Abstract

This challenge tests your ability to work with data modeling, query optimization, and modern data tools like **DuckDB** and **DBT**. These tools are critical for the systems we build at [DSCOVR](https://dscovr.io), and this challenge will give us insight into your approach to building **staging models** and **data marts** from raw data.

Take your time to read the challenge, and when you're ready, provide an estimate of how long it will take. If necessary, feel free to request an extension. This exercise is designed to be stimulating and fun, so push your boundaries and show off your skills!

**Red 🔴 - Green ✅ - Refactor 📝 - and have fun.**

---
## Objective

The challenge is to create a data pipeline using **DBT** and **DuckDB**, starting from raw data, transforming it into staging models, and finally creating **data marts**. 

Your goal is to build a **DBT project**:

1. Use a **public dataset** (details provided below) as the raw data source.
2. **Staging models**: to clean, normalize, and enrich the raw data.
3. **Data marts**: to extract key metrics and generate insights for decision-making.

---

## Dataset

We will use the **New York City Taxi Trips Dataset**, which contains trip records of taxis in NYC. This dataset is publicly available and can be downloaded using the following:

```shell
$ wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2026-07.parquet  
```

**Key Columns**:
- `VendorID`: ID of the provider.
- `tpep_pickup_datetime`, `tpep_dropoff_datetime`: trip start and end timestamps.
- `passenger_count`: number of passengers.
- `trip_distance`: distance of the trip in miles.
- `RatecodeID`: rate code.
- `fare_amount`: trip fare.
- `tip_amount`: tip amount.
- `total_amount`: total paid.
- And other useful columns for metric calculations.

---

## Tasks: Required Models

### 1. **Staging Models** [Mandatory]
Create staging models to clean and enrich the data by:
- **Timestamp formatting**: Standardize date/time formats and calculate:
  - Trip duration in minutes.
- **Data cleaning**: Remove rows with implausible values (e.g., negative `trip_distance`, `total_amount` ≤ 0).
- **Additional flags**:
  - Identify if the trip was prepaid (`payment_type` = 2).
  - Classify trips based on distance (e.g., short, medium, long).

### 2. **Data Marts**
Create the following **marts** to provide insights:

#### A. **Trips by Time of Day** [Mandatory]
- Calculate the total number of trips and total revenue (`total_amount`) for different time slots:
  - Morning (5:00-12:00)
  - Afternoon (12:00-17:00)
  - Evening (17:00-22:00)
  - Night (22:00-5:00)

#### B. **Top 5 Pickup Zones** [Mandatory]
- Identify the top 5 pickup zones (`PULocationID`) with:
  - The highest number of trips.
  - The highest total revenue.

#### C. **Driver/Rate Performance** [Mandatory]
- Analyze **tips**:
  - Calculate the average tip percentage (`tip_amount / total_amount`) for each `VendorID`.

#### D. **Distance Analysis** [Mandatory]
- Segment trips by distance (`trip_distance`):
  - **Short**: 0-2 miles.
  - **Medium**: 2-5 miles.
  - **Long**: >5 miles.
- Calculate the average trip duration and total revenue for each segment.

---

## Evaluation Criteria

1. **Clean and structured DBT project**:
   - Clear and well-organized models (raw, staging, marts).
   - Use of **DBT macros** to avoid repetitive logic.
2. **Query performance**:
   - Optimization of SQL queries for DuckDB.
3. **Documentation**:
   - A clear **README.md** explaining:
     - How to run the project.
     - Choices made in staging and marts models.
     - How to run any included tests.
4. **Bonus**:
   - Implementation of DBT tests (`unique`, `not null`, etc.).
   - Inclusion of visualizations for results (optional).

---

## Example Outputs

Here are examples of expected output tables:

### **A. Trips by Time of Day**
| Time Slot    | Total Trips | Total Revenue |
|--------------|-------------|---------------|
| Morning      | 1,234       | $12,345.67    |
| Afternoon    | 2,345       | $23,456.78    |
| Evening      | 3,456       | $34,567.89    |
| Night        | 1,123       | $11,234.56    |

---

### Repo qick start

```shell
$ uv venv
$ source .venv/bin/activate
$ uv sync
# Linux (amd64)
$ wget https://github.com/duckdb/duckdb/releases/download/v1.5.6/duckdb_cli-linux-amd64.zip && unzip duckdb_cli-linux-amd64.zip && mv duckdb .venv/bin/
# macOS (Intel / Apple Silicon)
$ wget https://github.com/duckdb/duckdb/releases/download/v1.5.6/duckdb_cli-osx-universal.zip && unzip duckdb_cli-osx-universal.zip && mv duckdb .venv/bin/
$ uv run dbt deps 
$ wget  https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2026-07.parquet -P data/raw
$ uv run dbt run
13:38:13  Running with dbt=1.12.5
13:38:13  Registered adapter: duckdb=1.11.0
13:38:13  Found 1 model, 616 macros
13:38:13  
13:38:13  Concurrency: 1 threads (target='dev')
13:38:13  
13:38:13  1 of 1 START sql table model main.staging_yellow_tripdata ...................... [RUN]
13:38:14  1 of 1 OK created sql table model main.staging_yellow_tripdata ................. [OK in 0.74s]
13:38:14  
13:38:14  Finished running 1 table model in 0 hours 0 minutes and 0.96 seconds (0.96s).
13:38:14  
13:38:14  Completed successfully
13:38:14  
13:38:14  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1

$ uv run duckdb data/db/yellow_tripdata.duckdb "select  * from staging_yellow_tripdata limit 10"
---

### Submission

1. Fork this repository and start your work on a new branch.
2. Include a `README.md` file with instructions on how to run the project.
3. Submit the repository as a `git bundle` or share it via GitHub/GitLab.

---

## Contacts

For questions or clarifications: [https://linktr.ee/mauro.malvestio](https://linktr.ee/mauro.malvestio)
