CREATE VIEW report.view_api_usage AS
  SELECT
    a.id,
    a.name,
    COUNT(au.id) AS usage_count,
    MAX(time) AS last_used
  FROM report.api_usage AS au
  LEFT JOIN report.api AS a ON a.id = au.api_id
  GROUP BY a.id, a.name

CREATE VIEW report.view_top_category AS
  WITH d_cat AS (
  	SELECT id, initcap(name) AS name FROM dataset_category
  )
  SELECT
    dc.name,
    COUNT(DISTINCT dcx.dataset_id) AS dataset_count,
    COUNT(DISTINCT d.portal_id) AS portal_count
  FROM dataset_category_xref AS dcx
  LEFT JOIN d_cat AS dc ON dcx.dataset_category_id = dc.id
  LEFT JOIN dataset AS d ON dcx.dataset_id = d.id
  GROUP BY dc.name
  ORDER BY COUNT(dcx.dataset_id) DESC
  LIMIT 100;

CREATE VIEW report.view_top_tag AS
  WITH d_tag AS (
    SELECT id, initcap(name) AS name FROM dataset_tag
  )
  SELECT
    dt.name,
    COUNT(DISTINCT dtx.dataset_id) AS dataset_count,
    COUNT(DISTINCT d.portal_id) AS portal_count
  FROM dataset_tag_xref AS dtx
  LEFT JOIN d_tag AS dt ON dtx.dataset_tag_id = dt.id
  LEFT JOIN dataset AS d ON dtx.dataset_id = d.id
  GROUP BY dt.name
  ORDER BY COUNT(dtx.dataset_id) DESC
  LIMIT 100;

CREATE VIEW report.view_top_publisher AS
  WITH d_pub AS (
    SELECT id, initcap(name) AS name FROM dataset_publisher
  )
  SELECT
    dp.name,
    COUNT(DISTINCT d.id) AS dataset_count,
    COUNT(DISTINCT d.portal_id) AS portal_count
  FROM dataset AS d
  LEFT JOIN d_pub AS dp ON d.publisher_id = dp.id
  GROUP BY dp.name
  ORDER BY COUNT(d.id) DESC
  LIMIT 100;

CREATE VIEW report.view_top_portal AS
  SELECT
    p.name,
    COUNT(d.id) AS dataset_count
  FROM dataset AS d
  LEFT JOIN portal AS p ON p.id = d.portal_id
  GROUP BY p.name
  ORDER BY COUNT(d.id) DESC
  LIMIT 100;

CREATE VIEW report.view_top_platform AS
  SELECT
    p.name,
    COUNT(d.id) AS dataset_count,
    COUNT(DISTINCT po.id) AS portal_count
  FROM dataset AS d
  LEFT JOIN portal AS po ON po.id = d.portal_id
  LEFT JOIN platform AS p ON p.id = po.platform_id
  GROUP BY p.name
  ORDER BY COUNT(d.id) DESC
  LIMIT 100;
