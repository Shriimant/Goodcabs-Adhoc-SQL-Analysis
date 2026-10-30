SELECT VERSION();
SHOW DATABASES;
SHOW TABLES FROM trips_db;
SHOW TABLES FROM targets_db;

#Business Request 1 : City-Level Fare and Trip Summary Report
#Generate a report that displays the total trips, average fare per km, average fare per trip, and the percentage contribution of each city's trips to the overall trips 
#This report will help in assessing trip volume, pricing efficiency, and each city's contribution to the overall tip count

#Fields:
-- city_name
-- total_trips
-- avg_fare_per km
-- avg_fare_per trip
-- %_contribution_to_total_trips

USE trips_db;

WITH city_trip_summary AS (
    SELECT
        c.city_name,
        COUNT(ft.trip_id) AS total_trips,
        SUM(ft.fare_amount) /
            NULLIF(SUM(ft.distance_travelled_km), 0)
            AS avg_fare_per_km,
        SUM(ft.fare_amount) /
            NULLIF(COUNT(ft.trip_id), 0)
            AS avg_fare_per_trip
    FROM fact_trips AS ft
    INNER JOIN dim_city AS c
        ON ft.city_id = c.city_id
    GROUP BY c.city_name
)

SELECT
    city_name,
    total_trips,
    ROUND(avg_fare_per_km, 2) AS avg_fare_per_km,
    ROUND(avg_fare_per_trip, 2) AS avg_fare_per_trip,
    ROUND(
        total_trips * 100.0 /
        SUM(total_trips) OVER (),
        2
    ) AS `%_contribution_to_total_trips`
FROM city_trip_summary
ORDER BY total_trips DESC;


# Business Request • 2: Monthly City-Level Trips Target Performance Report

-- Generate a report that evaluates the target performance for trips at the monthly and city level. For each city and month, compare the actual total trips with the target trips and
-- categorise the performance as follows:
-- • If actual trips are greater than target trips, mark it as "Above Target"
-- • If actual trips are less than or equal to target trips, mark it as "Bdow Target"

-- Additionally, calculate the % difference between actual and target trips to quantify the performance gap.

# Fields:
-- City_name
-- month name
-- actual_trips
-- target_trips
-- performance_status
-- %_difference


WITH actual_monthly_trips AS (
    SELECT
        ft.city_id,
        dd.start_of_month AS month,
        dd.month_name,
        COUNT(ft.trip_id) AS actual_trips
    FROM fact_trips AS ft
    INNER JOIN dim_date AS dd
        ON ft.date = dd.date
    GROUP BY
        ft.city_id,
        dd.start_of_month,
        dd.month_name
)

SELECT
    c.city_name,
    amt.month_name,
    amt.actual_trips,
    mtt.total_target_trips AS target_trips,

    CASE
        WHEN amt.actual_trips > mtt.total_target_trips
            THEN 'Above Target'
        ELSE 'Below Target'
    END AS performance_status,

    ROUND(
        (amt.actual_trips - mtt.total_target_trips)
        * 100.0 / NULLIF(mtt.total_target_trips, 0),
        2
    ) AS `%_difference`

FROM actual_monthly_trips AS amt

INNER JOIN dim_city AS c
    ON amt.city_id = c.city_id

INNER JOIN targets_db.monthly_target_trips AS mtt
    ON amt.city_id = mtt.city_id
    AND amt.month = mtt.month

ORDER BY
    c.city_name,
    amt.month;

# Business Request 3: City-Level Repeat Passenger Trip Frequency Report

-- Generate a report that shows the percentage distribution of repeat passengers by the number of trips they have taken in each city. Calculate the percentage of repeat passengers
-- who took 2 trips, 3 trips, and so on, up to IO trips. Each column should represent a trip count category, displaying the percentage Of repeat passengers who fall into that category 
-- out Of the total repeat passengers for that city. This report will help identify cities with high repeat trip frequency, which can indicate strong customer loyalty or frequent usage 
-- patterns.
-- Fields: city_name, 2-Trips, 3-Trips, 4-Trips, 5-Trips, e-Trips, 7-Trips, 8-Trips, 9-Trips, 10 -trips.



WITH city_repeat_distribution AS (
    SELECT
        city_id,
        trip_count,
        SUM(repeat_passenger_count) AS repeat_passengers
    FROM dim_repeat_trip_distribution
    GROUP BY
        city_id,
        trip_count
),

city_repeat_totals AS (
    SELECT
        city_id,
        SUM(repeat_passengers) AS total_repeat_passengers
    FROM city_repeat_distribution
    GROUP BY city_id
)

SELECT
    c.city_name,

    ROUND(
        SUM(CASE WHEN crd.trip_count = '2-Trips'
            THEN crd.repeat_passengers ELSE 0 END)
        * 100.0 / crt.total_repeat_passengers, 2
    ) AS `2-Trips`,

    ROUND(
        SUM(CASE WHEN crd.trip_count = '3-Trips'
            THEN crd.repeat_passengers ELSE 0 END)
        * 100.0 / crt.total_repeat_passengers, 2
    ) AS `3-Trips`,

    ROUND(
        SUM(CASE WHEN crd.trip_count = '4-Trips'
            THEN crd.repeat_passengers ELSE 0 END)
        * 100.0 / crt.total_repeat_passengers, 2
    ) AS `4-Trips`,

    ROUND(
        SUM(CASE WHEN crd.trip_count = '5-Trips'
            THEN crd.repeat_passengers ELSE 0 END)
        * 100.0 / crt.total_repeat_passengers, 2
    ) AS `5-Trips`,

    ROUND(
        SUM(CASE WHEN crd.trip_count = '6-Trips'
            THEN crd.repeat_passengers ELSE 0 END)
        * 100.0 / crt.total_repeat_passengers, 2
    ) AS `6-Trips`,

    ROUND(
        SUM(CASE WHEN crd.trip_count = '7-Trips'
            THEN crd.repeat_passengers ELSE 0 END)
        * 100.0 / crt.total_repeat_passengers, 2
    ) AS `7-Trips`,

    ROUND(
        SUM(CASE WHEN crd.trip_count = '8-Trips'
            THEN crd.repeat_passengers ELSE 0 END)
        * 100.0 / crt.total_repeat_passengers, 2
    ) AS `8-Trips`,

    ROUND(
        SUM(CASE WHEN crd.trip_count = '9-Trips'
            THEN crd.repeat_passengers ELSE 0 END)
        * 100.0 / crt.total_repeat_passengers, 2
    ) AS `9-Trips`,

    ROUND(
        SUM(CASE WHEN crd.trip_count = '10-Trips'
            THEN crd.repeat_passengers ELSE 0 END)
        * 100.0 / crt.total_repeat_passengers, 2
    ) AS `10-Trips`

FROM city_repeat_distribution AS crd

INNER JOIN city_repeat_totals AS crt
    ON crd.city_id = crt.city_id

INNER JOIN dim_city AS c
    ON crd.city_id = c.city_id

GROUP BY
    c.city_name,
    crt.total_repeat_passengers

ORDER BY c.city_name;


# Business Request 4: Identify Cities with Highest and Lowest Total New Passengers

-- Generate a report that calculates the total new passengers for each city and ranks them based on this value. Identify the top 3 cities with the highest number of new passengers as
-- well as the bottom 3 cities with the lowest number of new passengers, categorÉ1ng them as "Top 3" or "Bottom 3" accordingly.

-- Fields :
-- city_name
-- total_new_passengers
-- city_category ("Top 3" or 'Bottom 3")


WITH city_new_passengers AS (
    SELECT
        c.city_name,
        SUM(fps.new_passengers) AS total_new_passengers
    FROM fact_passenger_summary AS fps
    INNER JOIN dim_city AS c
        ON fps.city_id = c.city_id
    GROUP BY c.city_name
),

ranked_cities AS (
    SELECT
        city_name,
        total_new_passengers,

        ROW_NUMBER() OVER (
            ORDER BY total_new_passengers DESC, city_name
        ) AS highest_rank,

        ROW_NUMBER() OVER (
            ORDER BY total_new_passengers ASC, city_name
        ) AS lowest_rank

    FROM city_new_passengers
)

SELECT
    city_name,
    total_new_passengers,

    CASE
        WHEN highest_rank <= 3 THEN 'Top 3'
        WHEN lowest_rank <= 3 THEN 'Bottom 3'
    END AS city_category

FROM ranked_cities

WHERE highest_rank <= 3
   OR lowest_rank <= 3

ORDER BY
    CASE
        WHEN highest_rank <= 3 THEN 1
        ELSE 2
    END,
    CASE
        WHEN highest_rank <= 3 THEN highest_rank
        ELSE lowest_rank
    END;


# Business Request 5: Identify Month with Highest Revenue for Each City

-- Generate a report that identifies the month with the highest revenue for each city For each city, display the month_name, the revenue amount for that month, and the percentage
-- contribution of that month's revenue to the city's total revenue.

# Fields:

-- city_name
-- highest_revenue_month
-- revenue
-- percentage_contribution (%)


WITH city_monthly_revenue AS (
    SELECT
        ft.city_id,
        dd.start_of_month AS month,
        dd.month_name,
        SUM(ft.fare_amount) AS revenue
    FROM fact_trips AS ft
    INNER JOIN dim_date AS dd
        ON ft.date = dd.date
    GROUP BY
        ft.city_id,
        dd.start_of_month,
        dd.month_name
),

revenue_with_city_total AS (
    SELECT
        city_id,
        month,
        month_name,
        revenue,

        SUM(revenue) OVER (
            PARTITION BY city_id
        ) AS city_total_revenue,

        RANK() OVER (
            PARTITION BY city_id
            ORDER BY revenue DESC
        ) AS revenue_rank

    FROM city_monthly_revenue
)

SELECT
    c.city_name,
    rwct.month_name AS highest_revenue_month,
    ROUND(rwct.revenue, 2) AS revenue,

    ROUND(
        rwct.revenue * 100.0 /
        NULLIF(rwct.city_total_revenue, 0),
        2
    ) AS percentage_contribution

FROM revenue_with_city_total AS rwct

INNER JOIN dim_city AS c
    ON rwct.city_id = c.city_id

WHERE rwct.revenue_rank = 1

ORDER BY c.city_name, rwct.month;


# Business Request • 6: Repeat Passenger Rate Analysis

-- Generate a report that calculates two metrics:
-- l. Monthly Repeat Passenger Rate: Calculate the repeat passenger rate for each city and month by comparing the number Of repeat passengers to the total passengers.
-- 2. City-wide Repeat Passenger Rate: Calculate the overall repeat passenger rate for each city, considering all passengers across months

-- These metrics will provide insights into monthly repeat trends as well as the overall repeat behaviour for each city.
-- Fields:

-- city_name
-- month.
-- total_passengers.
-- repeat_passengers
-- monthly_repeat_passenger rate (0/0): Repeat passenger rate at the city and month level
-- city_repeat_passenger_rate (%): Overall repeat passenger rate for each city, aggregated across months.


WITH passenger_rates AS (
    SELECT
        fps.city_id,
        fps.month,
        fps.total_passengers,
        fps.repeat_passengers,

        -- Monthly repeat passenger rate
        fps.repeat_passengers * 100.0 /
        NULLIF(fps.total_passengers, 0)
        AS monthly_rate,

        -- Overall city-wide repeat passenger rate
        SUM(fps.repeat_passengers) OVER (
            PARTITION BY fps.city_id
        ) * 100.0 /

        NULLIF(
            SUM(fps.total_passengers) OVER (
                PARTITION BY fps.city_id
            ),
            0
        ) AS city_wide_rate

    FROM fact_passenger_summary AS fps
)

SELECT
    c.city_name,
    pr.month,
    pr.total_passengers,
    pr.repeat_passengers,

    ROUND(pr.monthly_rate, 2)
        AS `monthly_repeat_passenger_rate (%)`,

    ROUND(pr.city_wide_rate, 2)
        AS `city_repeat_passenger_rate (%)`

FROM passenger_rates AS pr

INNER JOIN dim_city AS c
    ON pr.city_id = c.city_id

ORDER BY
    c.city_name,
    pr.month;









