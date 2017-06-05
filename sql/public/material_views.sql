CREATE MATERIALIZED VIEW public.mview_latest_dataset AS
  SELECT * FROM public.view_latest_dataset;

CREATE MATERIALIZED VIEW public.mview_portal AS
  WITH data_summary AS (
    SELECT
      sd.portal_id,
      COUNT(sd.portal_dataset_id),
      MAX(sd.updated_time) AS updated_time
    FROM (
      SELECT DISTINCT ON (d.portal_id, d.portal_dataset_id)
        d.portal_dataset_id,
        d.portal_id,
        d.updated_time
      FROM public.dataset AS d
      ORDER BY d.portal_id, d.portal_dataset_id, d.version_number DESC
    ) sd
    GROUP BY sd.portal_id
  )
  SELECT
    p.id,
    p.name,
    p.url,
    p.description,
    ds.count AS dataset_count,
    ds.updated_time,
    pl.name AS platform,
    r.name AS region,
    ST_AsGeoJSON(r.geom, 6)::json AS location
  FROM public.portal AS p
  LEFT JOIN public.platform AS pl ON pl.id = p.platform_id
  LEFT JOIN public.location AS r ON r.id = p.location_id
  LEFT JOIN data_summary AS ds ON ds.portal_id = p.id;
