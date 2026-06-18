-- ============================================================
--  DIGITAL CAMPAIGN PERFORMANCE ANALYTICS
--  Tool: Google BigQuery
-- ============================================================


-- STEP 1: CREATE CLEAN TABLE

CREATE OR REPLACE TABLE `campaign_data.ad_campaign_clean` AS
SELECT
  user_id,
  timestamp,
  device_type,
  location,
  age_group,
  gender,
  ad_id,
  content_type,
  ad_topic,
  ad_target_audience,
  click_through_rate,
  conversion_rate,
  engagement_level,
  view_time,
  cost_per_click,
  ROI,
  FORMAT_TIMESTAMP('%Y-%m', timestamp) AS month,
  EXTRACT(HOUR FROM timestamp)          AS hour
FROM `campaign_data.ad_campaign`
WHERE
  click_through_rate IS NOT NULL
  AND conversion_rate IS NOT NULL
  AND ROI IS NOT NULL;


-- QUERY 1: CTR AND ROI BY CONTENT TYPE

SELECT
  content_type,
  COUNT(*)                                        AS total_ads,
  ROUND(AVG(click_through_rate) * 100, 2)        AS avg_ctr_pct,
  ROUND(AVG(conversion_rate) * 100, 2)           AS avg_conversion_rate_pct,
  ROUND(AVG(ROI), 2)                             AS avg_roi,
  ROUND(AVG(cost_per_click), 2)                  AS avg_cpc
FROM `campaign_data.ad_campaign_clean`
GROUP BY content_type
ORDER BY avg_ctr_pct DESC;


-- QUERY 2: ROI AND CONVERSION BY DEVICE TYPE

SELECT
  device_type,
  COUNT(*)                                        AS total_ads,
  ROUND(AVG(click_through_rate) * 100, 2)        AS avg_ctr_pct,
  ROUND(AVG(conversion_rate) * 100, 2)           AS avg_conversion_rate_pct,
  ROUND(AVG(ROI), 2)                             AS avg_roi,
  ROUND(AVG(cost_per_click), 2)                  AS avg_cpc
FROM `campaign_data.ad_campaign_clean`
GROUP BY device_type
ORDER BY avg_roi DESC;


-- QUERY 3: ENGAGEMENT LEVEL BREAKDOWN

SELECT
  engagement_level,
  COUNT(*)                                        AS total_ads,
  ROUND(AVG(click_through_rate) * 100, 2)        AS avg_ctr_pct,
  ROUND(AVG(conversion_rate) * 100, 2)           AS avg_conversion_rate_pct,
  ROUND(AVG(ROI), 2)                             AS avg_roi
FROM `campaign_data.ad_campaign_clean`
GROUP BY engagement_level
ORDER BY avg_roi DESC;


-- QUERY 4: PERFORMANCE BY AD TOPIC

SELECT
  ad_topic,
  COUNT(*)                                        AS total_ads,
  ROUND(AVG(click_through_rate) * 100, 2)        AS avg_ctr_pct,
  ROUND(AVG(conversion_rate) * 100, 2)           AS avg_conversion_rate_pct,
  ROUND(AVG(ROI), 2)                             AS avg_roi,
  ROUND(AVG(cost_per_click), 2)                  AS avg_cpc
FROM `campaign_data.ad_campaign_clean`
GROUP BY ad_topic
ORDER BY avg_ctr_pct DESC;


-- QUERY 5: PERFORMANCE BY LOCATION

SELECT
  location,
  COUNT(*)                                        AS total_ads,
  ROUND(AVG(click_through_rate) * 100, 2)        AS avg_ctr_pct,
  ROUND(AVG(conversion_rate) * 100, 2)           AS avg_conversion_rate_pct,
  ROUND(AVG(ROI), 2)                             AS avg_roi,
  ROUND(AVG(cost_per_click), 2)                  AS avg_cpc
FROM `campaign_data.ad_campaign_clean`
GROUP BY location
ORDER BY avg_roi DESC;


-- QUERY 6: PERFORMANCE BY AGE GROUP

SELECT
  age_group,
  COUNT(*)                                        AS total_ads,
  ROUND(AVG(click_through_rate) * 100, 2)        AS avg_ctr_pct,
  ROUND(AVG(conversion_rate) * 100, 2)           AS avg_conversion_rate_pct,
  ROUND(AVG(ROI), 2)                             AS avg_roi,
  ROUND(AVG(cost_per_click), 2)                  AS avg_cpc,
  ROUND(AVG(view_time), 1)                       AS avg_view_time_secs
FROM `campaign_data.ad_campaign_clean`
GROUP BY age_group
ORDER BY avg_roi DESC;


-- QUERY 7: MONTHLY PERFORMANCE TREND

SELECT
  month,
  COUNT(*)                                        AS total_ads,
  ROUND(AVG(click_through_rate) * 100, 2)        AS avg_ctr_pct,
  ROUND(AVG(conversion_rate) * 100, 2)           AS avg_conversion_rate_pct,
  ROUND(AVG(ROI), 2)                             AS avg_roi,
  ROUND(AVG(cost_per_click), 2)                  AS avg_cpc,
  ROUND(SUM(cost_per_click), 2)                  AS total_spend
FROM `campaign_data.ad_campaign_clean`
GROUP BY month
ORDER BY month ASC;


-- QUERY 8: PLANNED VS ACTUAL CTR (JOIN)

SELECT
  b.content_type,
  COUNT(*)                                        AS total_ads,
  ROUND(AVG(b.planned_budget), 2)                AS avg_planned_budget,
  ROUND(AVG(b.planned_ctr) * 100, 2)             AS avg_planned_ctr_pct,
  ROUND(AVG(a.click_through_rate) * 100, 2)      AS avg_actual_ctr_pct,
  ROUND(AVG(a.click_through_rate) * 100 -
        AVG(b.planned_ctr) * 100, 2)             AS ctr_gap,
  ROUND(AVG(a.ROI), 2)                           AS avg_roi
FROM `campaign_data.ad_campaign_clean` a
JOIN `campaign_data.campaign_budget` b
  ON a.ad_id = b.ad_id
GROUP BY b.content_type
ORDER BY ctr_gap DESC;


-- QUERY 9: BUDGET EFFICIENCY BY CAMPAIGN OBJECTIVE (JOIN)

SELECT
  b.campaign_objective,
  COUNT(*)                                        AS total_ads,
  ROUND(AVG(b.planned_budget), 2)                AS avg_planned_budget,
  ROUND(AVG(a.click_through_rate) * 100, 2)      AS avg_actual_ctr_pct,
  ROUND(AVG(a.conversion_rate) * 100, 2)         AS avg_conversion_rate_pct,
  ROUND(AVG(a.ROI), 2)                           AS avg_roi,
  ROUND(AVG(b.planned_budget) /
        NULLIF(AVG(a.ROI), 0), 2)                AS cost_per_roi_point
FROM `campaign_data.ad_campaign_clean` a
JOIN `campaign_data.campaign_budget` b
  ON a.ad_id = b.ad_id
GROUP BY b.campaign_objective
ORDER BY avg_roi DESC;


-- QUERY 10: PERFORMANCE LABELS (JOIN + CASE WHEN)

SELECT
  a.ad_id,
  a.content_type,
  a.ad_topic,
  a.location,
  a.age_group,
  b.campaign_objective,
  b.planned_budget,
  ROUND(b.planned_ctr * 100, 2)                  AS planned_ctr_pct,
  ROUND(a.click_through_rate * 100, 2)           AS actual_ctr_pct,
  ROUND((a.click_through_rate - b.planned_ctr)
        * 100, 2)                                 AS ctr_gap,
  ROUND(a.ROI, 2)                                AS actual_roi,
  CASE
    WHEN a.click_through_rate > b.planned_ctr
     AND a.ROI > 1.2    THEN 'Top Performer'
    WHEN a.click_through_rate >= b.planned_ctr
     AND a.ROI >= 1.0   THEN 'On Track'
    WHEN a.click_through_rate < b.planned_ctr
     AND a.ROI < 1.0    THEN 'Needs Review'
    ELSE 'Underperforming'
  END AS performance_label
FROM `campaign_data.ad_campaign_clean` a
JOIN `campaign_data.campaign_budget` b
  ON a.ad_id = b.ad_id
ORDER BY ctr_gap DESC;


-- SUMMARY: PORTFOLIO HEALTH CHECK (Subquery)

SELECT
  performance_label,
  COUNT(*)                        AS total_ads,
  ROUND(AVG(actual_roi), 2)      AS avg_roi,
  ROUND(AVG(ctr_gap), 2)         AS avg_ctr_gap
FROM (
  SELECT
    a.ad_id,
    ROUND(a.ROI, 2) AS actual_roi,
    ROUND((a.click_through_rate - b.planned_ctr) * 100, 2) AS ctr_gap,
    CASE
      WHEN a.click_through_rate > b.planned_ctr
       AND a.ROI > 1.2    THEN 'Top Performer'
      WHEN a.click_through_rate >= b.planned_ctr
       AND a.ROI >= 1.0   THEN 'On Track'
      WHEN a.click_through_rate < b.planned_ctr
       AND a.ROI < 1.0    THEN 'Needs Review'
      ELSE 'Underperforming'
    END AS performance_label
  FROM `campaign_data.ad_campaign_clean` a
  JOIN `campaign_data.campaign_budget` b
    ON a.ad_id = b.ad_id
)
GROUP BY performance_label
ORDER BY avg_roi DESC;
