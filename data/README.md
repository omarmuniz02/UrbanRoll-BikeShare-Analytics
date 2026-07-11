# Data Source Profiles
* **Rides Data (`vw_tableau_rides`):** Contains transaction records for 14,894 unique trips, tracking bike utilization, membership layers, and timestamps.
* **User Data (`babynames.users`):** Contains user-level demographic and sign-up tracking used to analyze user acquisition growth velocity.
# UrbanRoll: Executive Performance Insights (2024)

## Project Overview & Business Problem
Provide a 2-3 sentence hook explaining what UrbanRoll is and the specific business operational challenges the leadership team is facing regarding fleet balancing and growth retention.

## Stakeholder Questions Addressed
* **VP of Operations:** Where are the primary operational bottlenecks in our station network, and how can we optimize our rebalancing logistics?
* **VP of Marketing:** How effectively are we converting sign-ups into long-term active ridership?

## Technical Framework & Tools Used
* **SQL (Google BigQuery):** Advanced CTEs, Window Functions (`LAG`), Aggregations, and `NULLIF` error handling for user lifecycle analysis.
* **Tableau Desktop:** Data blending, custom dynamic KPI logic, and interactive parameters for executive filtering.

## Folder Directory Structure
* `data/`: Schema references and data profiles.
* `sql/`: Documented production-ready SQL scripts used for business logic validation.
* `dashboard/`: Packaged Tableau dashboard file (`.twbx`) for offline review.
