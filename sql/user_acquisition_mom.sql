-- ==========================================
-- Project: UrbanRoll Bike-Share Performance Analysis (2024)
-- Author: [Your Name]
-- Date: July 2026
-- Description: Tracking monthly user acquisition velocity to calculate 
--              Month-over-Month (MoM) signup growth rates.
-- Data Source: babynames.users (User Registration Table)
-- ==========================================

WITH monthly_signups AS (
    SELECT 
        DATE_TRUNC(created_at, MONTH) AS signup_month,
        COUNT(user_id) AS users
    FROM `project-e9cf5e3a-dcbe-4faa-bad.babynames.users`
    GROUP BY 1
)

SELECT 
    signup_month,
    users,
    LAG(users) OVER(ORDER BY signup_month) AS prev_month_count,
    
    -- Calculating MoM % variance; handling division by zero via NULLIF
    ROUND(
        (users - LAG(users) OVER(ORDER BY signup_month)) / 
        NULLIF(LAG(users) OVER(ORDER BY signup_month), 0) * 100, 
        2
    ) AS mom_growth_pct

FROM monthly_signups
ORDER BY signup_month;
