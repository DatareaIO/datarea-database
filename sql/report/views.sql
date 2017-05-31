CREATE VIEW report.view_api_usage AS
  SELECT
    a.id,
    a.name,
    COUNT(au.id) AS usage_count,
    MAX(time) AS last_used
  FROM report.api_usage AS au
  LEFT JOIN report.api AS a ON a.id = au.api_id
  GROUP BY a.id, a.name
