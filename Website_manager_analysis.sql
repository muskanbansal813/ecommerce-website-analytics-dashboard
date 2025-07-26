--ANALYSIS FOR WEBSITE MANAGER
 
--DESKTOP-N5H5P61\SQLEXPRESS01

USE Project3

--Tables
SELECT TOP 1 * FROM orders
SELECT TOP 1 * FROM order_items
SELECT TOP 1 * FROM order_item_refunds
SELECT TOP 1 * FROM products
SELECT  TOP 1 * FROM website_pageviews
SELECT TOP 1 * FROM website_sessions

select (SUM(o.price_usd) - SUM(oi.refund_amount_usd) ) as Revenue
from orders  as o
left join order_item_refunds as oi
on o.order_id = oi.order_id
-------------------------------------------------------------------------------------------------------
/**KPI’s to track:
 • Top website pages, entry pages.
 • Bounce rate.
 • Conversion rate.
 • Revenue per session for repeat sessions and new sessions. **/
---------------------------------------------------------------
--1. Top website pages
SELECT TOP 10 pageview_url, COUNT(*) AS total_pageviews
FROM website_pageviews
GROUP BY pageview_url 
ORDER BY total_pageviews DESC;

--2. Top Entry Pages (Entry pages are the first pages that users land on when they start a session on a website)

SELECT wp.pageview_url, COUNT(*) AS entry_page_count
FROM website_pageviews wp
JOIN (
    SELECT website_session_id, MIN(created_at) AS first_page_time
    FROM website_pageviews
    GROUP BY website_session_id
) AS FirstPage
ON wp.website_session_id = FirstPage.website_session_id
AND wp.created_at = FirstPage.first_page_time
GROUP BY wp.pageview_url;

--3.Bounce rate (Percentage of sessions where the user viewed only one page and then left)

SELECT 
    CAST(COUNT(CASE WHEN pageviews = 1 THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) AS bounce_rate_percentage
FROM (
    SELECT website_session_id, COUNT(*) AS pageviews
    FROM website_pageviews
    GROUP BY website_session_id
) AS session_counts;

--4.Conversion Rate  (The percentage of sessions that resulted in a conversion)

SELECT 
	COUNT(s.website_session_id) AS total_sessions, -- Total website sessions
    COUNT( o.website_session_id) AS converted_sessions, -- Sessions that resulted in an order
    CAST(COUNT(o.website_session_id) * 100.0 / NULLIF(COUNT(s.website_session_id), 0) AS DECIMAL(10,2)) 
    AS conversion_rate_percentage -- Overall conversion rate
FROM website_sessions s
LEFT JOIN orders o ON s.website_session_id = o.website_session_id;


--5.Revenue per session for repeat sessions and new sessions

WITH SessionType AS (
    SELECT 
        s.website_session_id,  
        s.user_id,  
        s.is_repeat_session,
        o.price_usd 
    FROM website_sessions s
    LEFT JOIN orders o  
        ON s.website_session_id = o.website_session_id  
)
SELECT 
    is_repeat_session,  
    COUNT( website_session_id) AS total_sessions,  
    ROUND(SUM(price_usd), 2) AS total_revenue, 
    CAST(SUM(price_usd) / NULLIF(COUNT(website_session_id), 0) AS DECIMAL(10,2)) AS revenue_per_session
FROM SessionType
GROUP BY is_repeat_session;

---------------------------------------------------------------------------------------
WITH UserSessionCounts AS (
    SELECT 
        user_id, 
        COUNT(website_session_id) AS session_count
    FROM website_sessions
    GROUP BY user_id
)
SELECT 
    SUM(CASE WHEN session_count = 1 THEN 1 ELSE 0 END) AS One_Time_Users,
    SUM(CASE WHEN session_count > 1 THEN 1 ELSE 0 END) AS Repeat_Users
FROM UserSessionCounts;


--------------------------------------------------------------------------------------------------------------------------------
 /*List of analyses to send regularly:
 • Identifying top website pages and top entry pages.
 • Analysis on bounce rate analysis.
 • Analysing landing page tests.
 • Landing page trend analysis.
 • Build conversion funnel for G-Search non-brand traffic from /lander-1 to /thankyou page, product conversion funnels.
 • Analysing conversion funnel tests for /billing v/s new /billing-2, product pathing analysis  */

----------------------------------------------------------------------------------------------------------------------------------
--1.Identifying top website pages and top entry pages

--2.Analysis on bounce rate analysis


--Bounce Rate by Traffic Source
WITH PageViewCounts AS (
    SELECT 
        s.website_session_id, 
        s.utm_source,  -- Traffic source
        COUNT(p.website_pageview_id) AS page_views
    FROM website_sessions s
    LEFT JOIN website_pageviews p ON s.website_session_id = p.website_session_id
    GROUP BY s.website_session_id, s.utm_source
)
SELECT 
    utm_source, 
    COUNT(*) AS total_sessions,  -- Total sessions per source
    SUM(CASE WHEN page_views = 1 THEN 1 ELSE 0 END) AS bounced_sessions, -- Bounced sessions per source
    CAST(SUM(CASE WHEN page_views = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) AS bounce_rate
FROM PageViewCounts
GROUP BY utm_source
ORDER BY bounce_rate DESC;

--Bounce Rate by Device Type
WITH PageViewCounts AS (
    SELECT 
        s.website_session_id, 
        s.device_type,  -- Device type (Mobile, Desktop, Tablet)
        COUNT(p.website_pageview_id) AS page_views
    FROM website_sessions s
    LEFT JOIN website_pageviews p ON s.website_session_id = p.website_session_id
    GROUP BY s.website_session_id, s.device_type
)
SELECT 
    device_type, 
    COUNT(*) AS total_sessions,  
    SUM(CASE WHEN page_views = 1 THEN 1 ELSE 0 END) AS bounced_sessions,  
    CAST(SUM(CASE WHEN page_views = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) AS bounce_rate
FROM PageViewCounts
GROUP BY device_type
ORDER BY bounce_rate DESC;

--Bounce Rate by Campaign (utm_campaign)
WITH PageViewCounts AS (
    SELECT 
        s.website_session_id, 
        s.utm_campaign,  
        COUNT(p.website_pageview_id) AS page_views
    FROM website_sessions s
    LEFT JOIN website_pageviews p ON s.website_session_id = p.website_session_id
    GROUP BY s.website_session_id, s.utm_campaign
)
SELECT 
    utm_campaign, 
    COUNT(*) AS total_sessions,  
    SUM(CASE WHEN page_views = 1 THEN 1 ELSE 0 END) AS bounced_sessions,  
    CAST(SUM(CASE WHEN page_views = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) AS bounce_rate
FROM PageViewCounts
GROUP BY utm_campaign
ORDER BY bounce_rate DESC;

--Bounce Rate by Time of Day / Day of Week
WITH PageViewCounts AS (
    SELECT 
        s.website_session_id, 
        DATEPART(HOUR, s.created_at) AS session_hour,  -- Extract hour of session start
        COUNT(p.website_pageview_id) AS page_views
    FROM website_sessions s
    LEFT JOIN website_pageviews p ON s.website_session_id = p.website_session_id
    GROUP BY s.website_session_id, DATEPART(HOUR, s.created_at)
)
SELECT 
    session_hour,  
    COUNT(*) AS total_sessions,  
    SUM(CASE WHEN page_views = 1 THEN 1 ELSE 0 END) AS bounced_sessions,  
    CAST(SUM(CASE WHEN page_views = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) AS bounce_rate
FROM PageViewCounts
GROUP BY session_hour
ORDER BY session_hour;

---------------------------------------------------------------------------------------------------------------------------------
--Analysing landing page tests

WITH session_counts AS (
    SELECT 
        s.website_session_id, 
        MIN(p.pageview_url) AS landing_page,  -- First page visited in a session
        COUNT(p.website_pageview_id) AS pageviews
    FROM website_sessions s
    LEFT JOIN website_pageviews p 
        ON s.website_session_id = p.website_session_id
    GROUP BY s.website_session_id
)
SELECT 
    landing_page,  
    COUNT(*) AS total_sessions,  -- Number of sessions per landing page
    SUM(CASE WHEN pageviews = 1 THEN 1 ELSE 0 END) AS bounced_sessions,  -- Bounce count
    CAST(SUM(CASE WHEN pageviews = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) 
         AS DECIMAL(10,2)) AS bounce_rate
FROM session_counts
GROUP BY landing_page
ORDER BY bounce_rate DESC;
--------------------------------------------------------------------------------------------
-- Landing page trend analysis.
WITH First_Pageviews AS (
    SELECT 
        wp.website_session_id,
        wp.pageview_url,
        ws.created_at AS session_start_time,
        ROW_NUMBER() OVER (
            PARTITION BY wp.website_session_id 
            ORDER BY wp.created_at ASC
        ) AS rn
    FROM website_pageviews wp
    JOIN website_sessions ws 
        ON wp.website_session_id = ws.website_session_id
)
SELECT 
    FORMAT(session_start_time, 'yyyy-MM') AS month_year,
    pageview_url AS landing_page,
    COUNT(*) AS session_count
FROM First_Pageviews
WHERE rn = 1  -- Only keep the first pageview for each session
GROUP BY FORMAT(session_start_time, 'yyyy-MM'), pageview_url
ORDER BY month_year, session_count DESC;

-----------------------------------------------------------------------------
--Build conversion funnel for G-Search non-brand traffic from /lander-1 to /thankyou page, product conversion funnels

--SELECT DISTINCT pageview_url FROM website_pageviews

WITH session_events AS (
    SELECT
        ws.website_session_id,
        --MAX(CASE WHEN wp.pageview_url IN ('/lander-1', '/lander-2', '/lander-3', '/lander-4', '/lander-5', '/home') THEN 1 ELSE 0 END) AS saw_lander,
		MAX(CASE WHEN wp.pageview_url IN ('/lander-1') THEN 1 ELSE 0 END) AS saw_lander,  --For lander-1 only
		MAX(CASE WHEN wp.pageview_url IN ('/products') THEN 1 ELSE 0 END) AS saw_product,
        MAX(CASE WHEN wp.pageview_url IN ('/the-hudson-river-mini-bear', '/the-birthday-sugar-panda', '/the-original-mr-fuzzy', '/the-forever-love-bear') THEN 1 ELSE 0 END) AS saw_specific_product,
        MAX(CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END) AS saw_cart,
        MAX(CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END) AS saw_shipping,
        MAX(CASE WHEN wp.pageview_url IN ('/billing', '/billing-2') THEN 1 ELSE 0 END) AS saw_billing,
        MAX(CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS completed_purchase
    FROM website_sessions ws
    LEFT JOIN website_pageviews wp 
        ON ws.website_session_id = wp.website_session_id
    WHERE ws.utm_source = 'gsearch'
       AND ws.utm_campaign = 'nonbrand'   
    GROUP BY ws.website_session_id
)
SELECT
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN saw_lander = 1 THEN website_session_id ELSE NULL END) AS lander_sessions,
    COUNT(DISTINCT CASE WHEN saw_product = 1 THEN website_session_id ELSE NULL END) AS product_page_sessions,
	 COUNT(DISTINCT CASE WHEN saw_specific_product = 1 THEN website_session_id ELSE NULL END) AS specific_product_page_sessions,
    COUNT(DISTINCT CASE WHEN saw_cart = 1 THEN website_session_id ELSE NULL END) AS cart_sessions,
    COUNT(DISTINCT CASE WHEN saw_shipping = 1 THEN website_session_id ELSE NULL END) AS shipping_sessions,
    COUNT(DISTINCT CASE WHEN saw_billing = 1 THEN website_session_id ELSE NULL END) AS billing_sessions,
    COUNT(DISTINCT CASE WHEN completed_purchase = 1 THEN website_session_id ELSE NULL END) AS completed_purchases
FROM session_events;


--------------------------------------------------------------------------------------------------------------

--Analysing conversion funnel tests for /billing v/s new /billing-2, product pathing analysis.
SELECT 
    wp.website_session_id,
    STRING_AGG(wp.pageview_url, ' -> ') WITHIN GROUP (ORDER BY wp.created_at) AS page_sequence,
    CASE 
        WHEN MAX(CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) = 1   --1 appears, it means the user visited the thank-you page (completed the funnel)
        THEN 'Converted' ELSE 'Dropped Off' 
    END AS conversion_status
FROM website_pageviews wp
JOIN website_sessions ws 
    ON wp.website_session_id = ws.website_session_id
GROUP BY wp.website_session_id;



-----------------------------------------------------------------------------------------------------------

select SUM(price_usd) from orders