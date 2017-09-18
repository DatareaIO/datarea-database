CREATE VIEW report.view_api_usage AS
  SELECT
    a.id,
    a.name,
    COUNT(au.id) AS usage_count,
    MAX(time) AS last_used
  FROM report.api_usage AS au
  LEFT JOIN report.api AS a ON a.id = au.api_id
  GROUP BY a.id, a.name

CREATE OR REPLACE VIEW report.view_statistics AS
  SELECT 'dataset' AS field, SUM(dataset_count) FROM mview_portal
  WHERE dataset_count IS NOT NULL
  UNION ALL
  SELECT 'file & link' AS field, COUNT(*) FROM dataset_file
  UNION ALL
  SELECT 'tag' AS field, COUNT(*) FROM dataset_tag
  UNION ALL
  SELECT 'category' AS field, COUNT(*) FROM dataset_category
  UNION ALL
  SELECT 'publisher' AS field, COUNT(*) FROM dataset_publisher
  UNION ALL
  SELECT 'dataset coverage' AS field, COUNT(*) FROM dataset_coverage;

CREATE OR REPLACE VIEW report.view_top_category AS
  SELECT
    initcap(dc.name) AS name,
    COUNT(DISTINCT dcx.dataset_id) AS dataset_count,
    COUNT(DISTINCT d.portal_id) AS portal_count
  FROM dataset_category_xref AS dcx
  LEFT JOIN dataset_category AS dc ON dcx.dataset_category_id = dc.id
  LEFT JOIN mview_latest_dataset AS d ON dcx.dataset_id = d.id
  GROUP BY initcap(dc.name)
  ORDER BY dataset_count DESC
  LIMIT 100;

CREATE OR REPLACE VIEW report.view_top_tag AS
  SELECT
    initcap(dt.name) AS name,
    COUNT(DISTINCT dtx.dataset_id) AS dataset_count,
    COUNT(DISTINCT d.portal_id) AS portal_count
  FROM dataset_tag_xref AS dtx
  LEFT JOIN dataset_tag AS dt ON dtx.dataset_tag_id = dt.id
  INNER JOIN mview_latest_dataset AS d ON dtx.dataset_id = d.id
  GROUP BY initcap(dt.name)
  ORDER BY dataset_count DESC
  LIMIT 100;

CREATE VIEW report.view_top_publisher AS
  SELECT
    initcap(d.publisher),
    COUNT(DISTINCT d.id) AS dataset_count
  FROM mview_latest_dataset AS d
  GROUP BY d.publisher
  ORDER BY COUNT(d.id) DESC
  LIMIT 100;

CREATE VIEW report.view_top_portal AS
  SELECT
    p.name,
    COUNT(d.id) AS dataset_count
  FROM mview_latest_dataset AS d
  LEFT JOIN portal AS p ON p.id = d.portal_id
  GROUP BY p.name
  ORDER BY COUNT(d.id) DESC
  LIMIT 100;

CREATE VIEW report.view_top_platform AS
  SELECT
    p.name,
    SUM(po.dataset_count) FILTER (WHERE po.dataset_count IS NOT NULL) AS dataset_count,
    COUNT(DISTINCT po.id) AS portal_count,
    COUNT(DISTINCT po.id) FILTER (WHERE po.dataset_count IS NOT NULL) AS effective_portal_count
  FROM mview_portal AS po
  LEFT JOIN platform AS p ON p.name = po.platform
  GROUP BY p.name, p.id
  ORDER BY SUM(po.dataset_count) DESC
  LIMIT 100;
