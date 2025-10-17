CREATE DATABASE hotel_reporting;
USE hotel_reporting;

-- REVENUE TABLE
CREATE TABLE revenue (
    revenue_id INT PRIMARY KEY,
    booking_id INT,
    room_revenue DECIMAL(10,2),
    fnb_revenue DECIMAL(10,2),
    spa_revenue DECIMAL(10,2),
    total_revenue DECIMAL(10,2),
    total_revenue_original DECIMAL(10,2),
    total_revenue_corrected DECIMAL(10,2),
    revenue_mismatch_flag BOOLEAN
);

-- BOOKINGS TABLE
CREATE TABLE bookings(
    booking_id INT PRIMARY KEY,
    guest_id INT,
    room_id INT,
    booking_date DATE,
    check_in DATE,
    check_out DATE,
    lead_time INT,
    nights INT,
    booking_channel VARCHAR(50),
    is_canceled BOOLEAN,
    num_guests INT
);

-- GUESTS TABLE
CREATE TABLE guests (
    guest_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    country VARCHAR(50),
    segment VARCHAR(50)
);

-- ROOMS TABLE
CREATE TABLE rooms (
    room_id INT PRIMARY KEY,
    room_type VARCHAR(50),
    capacity INT,
    base_rate DECIMAL(10,2)
);

SELECT * FROM bookings LIMIT 5;
SELECT * FROM guests LIMIT 5;
SELECT * FROM rooms LIMIT 5;
SELECT * FROM revenue LIMIT 5;

-- ANALYSIS

-- Occupancy Rate
SELECT 
    DATE(check_in) AS date,
    COUNT(DISTINCT room_id) AS rooms_occupied,
    (SELECT COUNT(*) FROM rooms) AS total_rooms,
    ROUND(COUNT(DISTINCT room_id) / (SELECT COUNT(*) FROM rooms) * 100, 2) AS occupancy_rate_pct
FROM bookings
WHERE is_canceled = 0
GROUP BY DATE(check_in)
ORDER BY date;

-- Revenue Breakdown by Service
SELECT 
    SUM(room_revenue) AS total_room_revenue,
    SUM(fnb_revenue) AS total_fnb_revenue,
    SUM(spa_revenue) AS total_spa_revenue,
    SUM(total_revenue) AS grand_total_revenue
FROM revenue;

-- Cancellation Rate
SELECT 
    ROUND(SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS cancellation_rate_pct
FROM bookings;

-- Cancellation Impact
SELECT 
    COUNT(*) AS canceled_bookings,
    COUNT(*) * (
        SELECT AVG(r.total_revenue)
        FROM bookings b
        JOIN revenue r ON b.booking_id = r.booking_id
        WHERE b.is_canceled = 0
    ) AS estimated_revenue_lost
FROM bookings
WHERE is_canceled = 1;

-- Average Daily Rate (ADR)
SELECT 
    ROUND(SUM(r.total_revenue) / SUM(b.nights), 2) AS ADR
FROM bookings b
JOIN revenue r ON b.booking_id = r.booking_id
WHERE b.is_canceled = 0;

-- Revenue per Available Room (RevPAR)
SELECT 
    DATE(b.check_in) AS date,
    ROUND(SUM(r.total_revenue) / (COUNT(DISTINCT b.room_id)), 2) AS RevPAR
FROM bookings b
JOIN revenue r ON b.booking_id = r.booking_id
WHERE b.is_canceled = 0
GROUP BY DATE(b.check_in)
ORDER BY date;

-- Average Lenght of Stay
SELECT 
    b.room_id,
    r.room_type,
    ROUND(AVG(b.nights), 2) AS ALOS
FROM bookings b
JOIN rooms r ON b.room_id = r.room_id
WHERE b.is_canceled = 0
GROUP BY b.room_id, r.room_type
ORDER BY ALOS DESC;

-- Monthly Revenue
SELECT 
    DATE_FORMAT(b.check_in, '%Y-%m') AS month,
    ROUND(SUM(r.total_revenue), 2) AS total_monthly_revenue
FROM bookings b
JOIN revenue r ON b.booking_id = r.booking_id
WHERE b.is_canceled = 0
GROUP BY DATE_FORMAT(b.check_in, '%Y-%m')
ORDER BY month;

-- Busy Season Identification (by month)
SELECT 
    MONTHNAME(check_in) AS month_name,
    COUNT(booking_id) AS total_bookings
FROM bookings
WHERE is_canceled = 0
GROUP BY MONTH(check_in), MONTHNAME(check_in)
ORDER BY total_bookings DESC;

SELECT 
    ROUND(SUM(r.total_revenue), 2) AS total_revenue,
    ROUND(SUM(r.room_revenue), 2) AS total_room_revenue,
    ROUND(SUM(r.fnb_revenue), 2) AS total_fnb_revenue,
    ROUND(SUM(r.spa_revenue), 2) AS total_spa_revenue,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    ROUND(AVG(b.nights), 2) AS avg_length_of_stay
FROM bookings b
JOIN revenue r ON b.booking_id = r.booking_id
WHERE b.is_canceled = 0;