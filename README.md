# NYC Yellow Taxi Analytics — dbt & DuckDB

A local analytics pipeline built for the DSCOVR Data Engineering Challenge using NYC Yellow Taxi trip data for July 2026.

The project transforms raw Parquet records into a cleaned and enriched staging table, four analytical marts, and an additional duration-quality mart.

## Architecture

```text
yellow_tripdata_2026-07.parquet
              |
              v
staging_yellow_tripdata
              |
              +--> mart_trips_by_time_of_day
              +--> mart_top_pickup_zones
              +--> mart_vendor_rate_performance
              +--> mart_distance_analysis
              +--> mart_duration_data_quality
```

DuckDB reads the Parquet source directly. All marts reference staging through dbt's `ref()`, which defines their dependencies and build order.

All six models are materialized as tables. This provides a persisted staging dataset for downstream aggregations and results that can be inspected without rerunning the transformations.

## Project structure

```text
models/
├── staging/
│   ├── staging_yellow_tripdata.sql
│   └── schema.yml
└── marts/
    ├── mart_trips_by_time_of_day.sql
    ├── mart_top_pickup_zones.sql
    ├── mart_vendor_rate_performance.sql
    ├── mart_distance_analysis.sql
    ├── mart_duration_data_quality.sql
    └── schema.yml

macros/
└── classify_distance.sql

tests/
├── assert_time_of_day_reconciliation.sql
├── assert_distance_analysis_reconciliation.sql
└── assert_duration_quality_reconciliation.sql

notebooks/
└── results_analysis.ipynb

docs/images/
├── trips_and_revenue_by_time_of_day.png
├── top_pickup_zones.png
└── average_duration_by_distance.png
```

## Setup and execution

### Requirements

- Python compatible with `pyproject.toml`.
- `uv` for environment and dependency management.
- Internet access for installing dependencies and downloading the dataset.

The DuckDB CLI can be used for manual inspection. The dbt pipeline and notebook use the DuckDB Python package.

Run all commands from the repository root.

### 1. Install dependencies

```shell
uv sync
uv run dbt deps
```

The local `profiles.yml` configures the development database at:

```text
data/db/yellow_tripdata.duckdb
```

### 2. Download the dataset

On Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force data/raw, data/db

Invoke-WebRequest `
    -Uri "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2026-07.parquet" `
    -OutFile "data/raw/yellow_tripdata_2026-07.parquet"
```

On Linux or macOS:

```shell
mkdir -p data/raw data/db

curl -L --fail \
  https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2026-07.parquet \
  -o data/raw/yellow_tripdata_2026-07.parquet
```

### 3. Validate the environment

```shell
uv run dbt debug --profiles-dir .
```

### 4. Build the models

```shell
uv run dbt run --profiles-dir .
```

### 5. Run the tests

```shell
uv run dbt test --profiles-dir .
```

Alternatively, build and test together:

```shell
uv run dbt build --profiles-dir .
```

## Modeling decisions

### Explicit staging schema

Staging preserves one row per source trip record. It selects the fields needed for the challenge rather than using `SELECT *`, and standardizes column names to snake_case.

The model does not introduce a trip identifier or deduplicate records. Uniqueness is tested at the explicitly defined grain of each mart.

### Basic cleaning

Staging retains records satisfying:

```sql
trip_distance >= 0
and total_amount > 0
```

These predicates exclude negative distances, non-positive total amounts, and null values in either field.

Profiling recorded:

| Population | Records |
|---|---:|
| Raw source | 3,530,109 |
| Cleaned staging | 3,514,801 |
| Removed | 15,308 |

No additional upper-bound filter is applied to distance.

### Duration precision

Profiling identified positive trips shorter than one minute. Duration is calculated at second-level precision and converted to decimal minutes:

```sql
datediff(
    'second',
    tpep_pickup_datetime,
    tpep_dropoff_datetime
) / 60.0
```

For example, a 40-second trip retains a duration of approximately 0.667 minutes.

### Duration-quality flag

Staging adds `duration_quality_status`:

| Status | Definition |
|---|---|
| `valid` | Dropoff is later than pickup |
| `zero_duration` | Pickup and dropoff timestamps are equal |
| `negative_duration` | Dropoff is earlier than pickup |

This flag describes temporal consistency. It does not certify the overall validity of a trip.

After basic cleaning, profiling recorded:

| Status | Records |
|---|---:|
| `valid` | 3,472,496 |
| `zero_duration` | 42,305 |

The negative-duration record identified in the raw source did not survive the basic cleaning predicates.

Timestamp anomalies are retained because those records can still contain useful revenue and distance information. Their status makes them available for monitoring and allows downstream models to apply explicit exclusions.

Non-null tests on both timestamps detect missing inputs that the current classification does not handle separately.

### Metric-specific populations

Only `mart_distance_analysis` filters to:

```sql
duration_quality_status = 'valid'
```

This protects its average-duration metric from zero and negative durations.

The other analytical marts retain all cleaned staging records because their metrics do not use trip duration.

Consequently, counts and revenue in the distance mart represent a smaller population than those in the time-of-day mart.

### Distance-classification macro

The reusable `classify_distance` macro defines the rule. Staging calls it to materialize `distance_category`; downstream marts consume that column.

| Category | Distance in miles |
|---|---|
| `short` | 0 ≤ distance < 2 |
| `medium` | 2 ≤ distance ≤ 5 |
| `long` | distance > 5 |

The boundaries resolve the overlapping wording of the challenge: exactly 2 miles belongs to `medium`, and exactly 5 miles also belongs to `medium`.

Centralizing the rule keeps the staging query readable and makes the classification reusable without repeating its `CASE` expression.

### Payment flag

`is_prepaid` follows the challenge's specified convention:

```text
payment_type = 2 → true
```

It should be interpreted as a challenge-specific flag.

### Monetary outputs

Revenue is calculated from `total_amount` and rounded after aggregation to two decimal places.

The source monetary fields retain their floating-point representation. Rounding makes the outputs readable; it does not convert the underlying values to fixed-point financial amounts.

## Analytical marts

| Model | Grain | Metrics |
|---|---|---|
| `mart_trips_by_time_of_day` | One row per time category | Trip count, total revenue |
| `mart_top_pickup_zones` | One row per selected pickup zone | Trip count, total revenue |
| `mart_vendor_rate_performance` | One row per vendor | Average trip-level tip percentage |
| `mart_distance_analysis` | One row per distance category | Trip count, average duration, total revenue |
| `mart_duration_data_quality` | One row per observed duration issue type | Affected rows and revenue, amount and distance statistics |

### Trips by time of day

Categories use pickup time, with inclusive starting boundaries and exclusive ending boundaries:

- Morning: 05:00–12:00.
- Afternoon: 12:00–17:00.
- Evening: 17:00–22:00.
- Night: 22:00–05:00.

No timezone conversion is applied to the source timestamps.

### Top pickup zones

The model selects five zones ordered by trip count and reports their revenue.

It does not produce an independent top-five ranking by revenue.

### Vendor tip performance

The metric is:

```sql
avg(tip_amount / total_amount) * 100
```

Each trip has equal weight. This differs from calculating `sum(tip_amount) / sum(total_amount)`.

Staging already guarantees a positive denominator. Results are grouped by vendor, not by individual driver.

### Bonus duration-quality mart

The additional mart reports only non-valid duration statuses:

- `issue_type`
- `affected_rows`
- `affected_rows_pct`
- `affected_revenue`
- `avg_total_amount`
- `avg_trip_distance`
- `max_trip_distance`

It makes the anomalies intentionally retained in staging visible for inspection.

`affected_rows_pct` is the share of an issue type among anomalous records, not among all staging records. With only `zero_duration` present, its value is 100%.

## Testing approach

The suite contains 18 data tests and one unit test.

### Mart grain

`unique` and `not_null` tests check the category or identifier defining each mart's grain.

These checks detect duplicate groups and unidentified groups. Staging attributes such as vendor ID are not tested for uniqueness because multiple trips legitimately share them.

### Population reconciliation

Three SQL tests compare:

- Time-of-day trip counts and revenue with all staging records.
- Distance-analysis trip counts and revenue with valid-duration staging records.
- Duration-quality affected-row counts with anomalous staging records.

Revenue comparisons allow small differences from separately rounded group totals: $0.03 for time categories and $0.02 for distance categories.

These tests protect the intended population of each mart. They do not independently verify every category assignment.

### Timestamp completeness

`not_null` tests on pickup and dropoff timestamps verify that inputs required for duration calculation and pickup-time classification are present.

### Category contracts

`accepted_values` tests constrain duration statuses, distance categories, and time-of-day categories to their documented vocabulary.

They protect category names against future changes, rather than proving correct assignment of each record.

### Staging duration unit test

The unit test replaces the raw source with three artificial records and executes the actual staging model:

| Input case | Expected duration | Expected status |
|---|---:|---|
| 40-second trip | 40 / 60 minutes | `valid` |
| Equal timestamps | 0 minutes | `zero_duration` |
| Dropoff 30 seconds before pickup | −0.5 minutes | `negative_duration` |

It verifies duration precision, anomaly classification, and retention of these records after basic cleaning.

Run only this test with:

```shell
uv run dbt test --profiles-dir . --select staging_duration_cases
```

The latest local validation completed with six models built and all 19 tests passing.

## Visualizations

The notebook reads the materialized marts directly from DuckDB. It does not reimplement their aggregations.

### Trips and revenue by time of day

![Trips and revenue by time of day](docs/images/trips_and_revenue_by_time_of_day.png)

Evening has the highest trip count and total revenue. All cleaned staging records are included.

### Top five pickup zones by trip count

![Top pickup zones](docs/images/top_pickup_zones.png)

Zone 161 has the most trips, while zone 132 generates the most revenue among the five selected zones. Both charts show the same selection.

### Average duration by distance category

![Average duration by distance](docs/images/average_duration_by_distance.png)

Average duration increases across distance categories. Only trips with valid duration are included.

### Run the notebook

Install the development dependencies with `uv sync`.

In VS Code, open `notebooks/results_analysis.ipynb` and select the project's `.venv` Python interpreter as the notebook kernel.

Run the cells in order. The notebook exports figures to `docs/images`.

Close the notebook's DuckDB connection before rebuilding the database.

## Limitations and assumptions

- Cleaning covers the specified distance and amount predicates; it is not a complete validation of all source attributes.
- Positive distance outliers remain. Profiling observed a maximum distance of 318,129.1 miles, so aggregate results should be interpreted with this limitation.
- Missing timestamps are detected by tests; they do not have a separate quality status.
- No trip key, deduplication rule, or pickup-zone lookup is introduced.
- The pickup-zone mart ranks by trip count only.
- All models use full table materialization; incremental processing is outside this single-file implementation.