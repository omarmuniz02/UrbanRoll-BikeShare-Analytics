-- ============================================================================
-- Project: UrbanRoll Bike-Share Analytics Pipeline (2024)
-- File: urbanroll_analysis_pipeline.sql
-- Author: Junior Data Analyst
-- Date: July 2026
--
-- Description:
-- End-to-end SQL analysis supporting the UrbanRoll Executive Performance
-- Insights Dashboard. This pipeline covers data auditing, rider segmentation,
-- hourly demand patterns, trip-duration analysis, station network flow, and
-- month-over-month customer acquisition growth.
-- ============================================================================


-- ============================================================================
-- STEP 1: DATA CLEANING AND QUALITY AUDIT
-- ============================================================================
-- Stakeholder: Data Engineering / Operations
--
-- Objective:
-- Identify potential system glitches, accidental unlocks, or immediate
-- cancellations represented by trips under two minutes or with zero distance.
-- ============================================================================

SELECT
    COUNTIF(
        TIMESTAMP_DIFF(end_time, start_time, MINUTE) < 2
    ) AS short_duration_trips,

    COUNTIF(distance_km = 0) AS zero_distance_trips

FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.rides`;


-- ============================================================================
-- STEP 2: HOURLY COMMUTE DEMAND
-- ============================================================================
-- Stakeholder: Logistics Scheduling Lead
--
-- Objective:
-- Analyze ride volume by hour to identify peak demand periods and determine
-- the most effective timing for manual fleet rebalancing.
-- ============================================================================

SELECT
    EXTRACT(HOUR FROM start_time) AS hour_of_day,
    COUNT(*) AS ride_count

FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.rides`

GROUP BY hour_of_day
ORDER BY hour_of_day;


-- ============================================================================
-- STEP 3: RIDER SEGMENTATION AND ENGAGEMENT
-- ============================================================================
-- Stakeholder: VP of Marketing / Product Team
--
-- Objective:
-- Compare ride volume, average distance, and average trip duration across
-- membership levels to understand how rider segments use the network.
-- ============================================================================

SELECT
    u.membership_level,
    COUNT(r.ride_id) AS ride_count,
    ROUND(AVG(r.distance_km), 2) AS avg_distance_km,
    ROUND(
        AVG(TIMESTAMP_DIFF(r.end_time, r.start_time, MINUTE)),
        1
    ) AS avg_duration_minutes

FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.rides` AS r

JOIN `project-e9cf5e3a-dcbe-4faa-bad.babynames.users` AS u
    ON r.user_id = u.user_id

GROUP BY u.membership_level
ORDER BY ride_count DESC;


-- ============================================================================
-- STEP 4: TRIP-DURATION SEGMENTATION
-- ============================================================================
-- Stakeholder: Fleet Allocation Lead
--
-- Objective:
-- Classify trips into short, medium, and long-duration groups to measure how
-- different ride profiles affect bike availability and asset utilization.
-- ============================================================================

SELECT
    CASE
        WHEN TIMESTAMP_DIFF(end_time, start_time, MINUTE) < 10
            THEN 'Short (<10M)'

        WHEN TIMESTAMP_DIFF(end_time, start_time, MINUTE) BETWEEN 11 AND 30
            THEN 'Medium (11-30M)'

        ELSE 'Long (+30M)'
    END AS ride_category,

    COUNT(*) AS rides

FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.rides`

GROUP BY ride_category
ORDER BY rides DESC;


-- ============================================================================
-- STEP 5: MOST ACTIVE START STATIONS
-- ============================================================================
-- Stakeholder: Station Deployment Team
--
-- Objective:
-- Identify the stations generating the highest number of ride departures to
-- understand where customer demand is most heavily concentrated.
-- ============================================================================

SELECT
    s.station_name,
    COUNT(r.ride_id) AS total_starts

FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.rides` AS r

JOIN `project-e9cf5e3a-dcbe-4faa-bad.babynames.stations` AS s
    ON r.start_station_id = s.station_id

GROUP BY s.station_name
ORDER BY total_starts DESC;


-- ============================================================================
-- STEP 6: STATION NET FLOW MODEL
-- ============================================================================
-- Stakeholder: VP of Operations
--
-- Objective:
-- Compare station arrivals and departures to identify recurring inventory
-- drains and accumulation points across the bike-share network.
--
-- Net Flow Formula:
--     Total Arrivals - Total Departures
--
-- Interpretation:
--     Negative Net Flow = Inventory Drain / Source Station
--     Positive Net Flow = Inventory Accumulation / Sink Station
-- ============================================================================

WITH departures AS (
    SELECT
        start_station_id,
        COUNT(*) AS total_departures

    FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.rides`

    GROUP BY start_station_id
),

arrivals AS (
    SELECT
        end_station_id,
        COUNT(*) AS total_arrivals

    FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.rides`

    GROUP BY end_station_id
)

SELECT
    s.station_name,
    IFNULL(a.total_arrivals, 0) AS total_arrivals,
    IFNULL(d.total_departures, 0) AS total_departures,

    IFNULL(a.total_arrivals, 0)
        - IFNULL(d.total_departures, 0) AS net_flow

FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.stations` AS s

JOIN departures AS d
    ON s.station_id = d.start_station_id

JOIN arrivals AS a
    ON s.station_id = a.end_station_id

-- The largest inventory drains appear first.
ORDER BY net_flow ASC;


-- ============================================================================
-- STEP 7: MONTH-OVER-MONTH USER ACQUISITION GROWTH
-- ============================================================================
-- Stakeholder: VP of Marketing
--
-- Objective:
-- Measure monthly account creation velocity and calculate month-over-month
-- growth using window functions.
--
-- NULLIF prevents division-by-zero errors when the previous month's account
-- creation total is zero.
-- ============================================================================

WITH monthly_signups AS (
    SELECT
        DATE_TRUNC(created_at, MONTH) AS signup_month,
        COUNT(user_id) AS users

    FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.users`

    GROUP BY signup_month
)

SELECT
    signup_month,
    users,

    LAG(users) OVER (
        ORDER BY signup_month
    ) AS previous_month_users,

    ROUND(
        (
            users
            - LAG(users) OVER (ORDER BY signup_month)
        )
        / NULLIF(
            LAG(users) OVER (ORDER BY signup_month),
            0
        )
        * 100,
        2
    ) AS mom_growth_pct

FROM monthly_signups

ORDER BY signup_month;
