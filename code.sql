-- to get all the sessions id's which didn't click through further into website
WITH single_session AS ( SELECT website_session_id, COUNT(*)
FROM website_pageviews
GROUP BY 1
HAVING COUNT(*) = 1)

-- to calculate overall performance and efficiencies, device-wise sessions, orders etc.
SELECT year(website_sessions.created_at) year,
quarter(website_sessions.created_at) AS Quarter,
monthname(website_sessions.created_at) AS Month,
COUNT(website_sessions.website_session_id) AS total_sessions,
COUNT(orders.order_id) AS total_orders,
COUNT(orders.order_id)/COUNT(website_sessions.website_session_id) AS conversion_rate,
COUNT(single_session.website_session_id)/COUNT(website_sessions.website_session_id) AS bounce_rate,
SUM(price_usd)/COUNT(orders.order_id) AS revenue_per_order,
SUM(price_usd)/COUNT(website_sessions.website_session_id) AS revenue_per_session,
COUNT(CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
COUNT(CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions,
COUNT(CASE WHEN device_type = 'mobile' THEN orders.website_session_id ELSE NULL END) AS mobile_orders,
COUNT(CASE WHEN device_type = 'desktop' THEN orders.website_session_id ELSE NULL END) AS desktop_orders,
COUNT(CASE WHEN device_type = 'mobile' THEN orders.website_session_id ELSE NULL END)/
COUNT(CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mob_convrsn_rt,
COUNT(CASE WHEN device_type = 'desktop' THEN orders.website_session_id ELSE NULL END)/
COUNT(CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS dsktp_convrsn_rt,
COUNT(CASE WHEN device_type = 'mobile' THEN single_session.website_session_id ELSE NULL END)/
COUNT(CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mob_bnc_rt,
COUNT(CASE WHEN device_type = 'desktop' THEN single_session.website_session_id ELSE NULL END)/
COUNT(CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS dsktp_bnc_rt,
SUM(CASE WHEN device_type = 'mobile' THEN price_usd ELSE NULL END)/COUNT(CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mob_rev_pr_sessn,
SUM(CASE WHEN device_type = 'desktop' THEN price_usd ELSE NULL END)/COUNT(CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS dsktp_rev_pr_sessn,
SUM(CASE WHEN device_type = 'mobile' THEN price_usd ELSE NULL END)/COUNT(CASE WHEN device_type = 'mobile' THEN orders.website_session_id ELSE NULL END) AS mob_rev_pr_ord,
SUM(CASE WHEN device_type = 'desktop' THEN price_usd ELSE NULL END)/COUNT(CASE WHEN device_type = 'desktop' THEN orders.website_session_id ELSE NULL END) AS dsktp_rev_pr_ord
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
LEFT JOIN single_session
ON website_sessions.website_session_id = single_session.website_session_id
GROUP BY 1,2,3


-- to get the performance of different channels through which orders are being placed

SELECT year(website_sessions.created_at) AS year,
quarter(website_sessions.created_at) AS quarter,
monthname(website_sessions.created_at) AS Month,
COUNT(website_sessions.website_session_id) AS sessions,
COUNT(order_id) AS orders,
COUNT(CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS gsearch_nonbrand_order,
COUNT(CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS bsearch_nonbrand_order,
COUNT(CASE WHEN utm_campaign = 'brand' THEN order_id ELSE NULL END) AS brand_campaign_order,
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END) AS organic_search_order,
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END) AS direct_typein_order
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2,3

-- code to get revenue and margins of products available on website

SELECT 
year(order_items.created_at) AS year,
monthname(order_items.created_at) AS month,
COUNT(order_id) AS total_sales,
SUM(price_usd) AS total_reven,
COUNT(CASE WHEN product_name = 'The Original Mr. Fuzzy' THEN price_usd ELSE NULL END) AS Fuzzy_sales,
SUM(CASE WHEN product_name = 'The Original Mr. Fuzzy' THEN price_usd ELSE 0 END) AS Fuzzy_revenue,
SUM(CASE WHEN product_name = 'The Original Mr. Fuzzy' THEN price_usd - cogs_usd ELSE 0 END) AS Fuzzy_marg,
COUNT(CASE WHEN product_name = 'The Forever Love Bear' THEN price_usd ELSE NULL END) AS Bear_sales,
SUM(CASE WHEN product_name = 'The Forever Love Bear' THEN price_usd ELSE 0 END) AS Bear_revenue,
SUM(CASE WHEN product_name = 'The Forever Love Bear' THEN price_usd - cogs_usd ELSE 0 END) AS Bear_marg,
COUNT(CASE WHEN product_name = 'The Birthday Sugar Panda' THEN price_usd ELSE NULL END) AS panda_sales,
SUM(CASE WHEN product_name = 'The Birthday Sugar Panda' THEN price_usd ELSE 0 END) AS panda_revenue,
SUM(CASE WHEN product_name = 'The Birthday Sugar Panda' THEN price_usd - cogs_usd ELSE 0 END) AS panda_marg,
COUNT(CASE WHEN product_name = 'The Hudson River Mini bear' THEN price_usd ELSE NULL END) AS minibear_sales,
SUM(CASE WHEN product_name = 'The Hudson River Mini bear' THEN price_usd ELSE 0 END) AS minibear_revenue,
SUM(CASE WHEN product_name = 'The Hudson River Mini bear' THEN price_usd - cogs_usd ELSE 0 END) AS minibear_marg
FROM order_items
LEFT JOIN products
ON order_items.product_id = products.product_id
GROUP BY 1,2

-- code to get overall cross-selling of products

WITH primary_table AS (SELECT order_table.order_id, product_id AS primary_item
FROM (SELECT order_id,
COUNT(*) AS count
FROM order_items
GROUP BY 1
HAVING COUNT(*) > 1) AS order_table
LEFT JOIN order_items
ON order_table.order_id = order_items.order_id
WHERE is_primary_item = 1),

cross_table AS (SELECT order_table.order_id, product_id AS cross_item
FROM (SELECT order_id,
COUNT(*) AS count
FROM order_items
GROUP BY 1
HAVING COUNT(*) > 1) AS order_table
LEFT JOIN order_items
ON order_table.order_id = order_items.order_id
WHERE is_primary_item = 0),

final_table AS (SELECT primary_table.order_id, primary_item, cross_item
FROM primary_table
INNER JOIN cross_table
ON primary_table.order_id = cross_table.order_id)

SELECT primary_item,
COUNT(CASE WHEN cross_item = 1 THEN 1 ELSE NULL END) AS fuzzy_bear,
COUNT(CASE WHEN cross_item = 2 THEN 1 ELSE NULL END) AS Love_bear,
COUNT(CASE WHEN cross_item = 3 THEN 1 ELSE NULL END) AS Sugar_Panda,
COUNT(CASE WHEN cross_item = 4 THEN 1 ELSE NULL END) AS Mini_bear
FROM final_table
GROUP BY 1
ORDER BY 1
