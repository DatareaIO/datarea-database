CREATE MATERIALIZED VIEW public.mview_latest_dataset AS
  SELECT DISTINCT ON (d.portal_dataset_id, dpx.portal_id)
    d.id,
    d.identifier,
    dpx.portal_id,
    d.modified
  FROM dataset AS d
  LEFT JOIN dataset_portal_xref AS dpx ON dpx.dataset_id = d.id
  ORDER BY d.portal_dataset_id, dpx.portal_id, d.modified DESC;

CREATE MATERIALIZED VIEW public.mview_portal AS
  WITH data_summary AS (
    SELECT
      sd.portal_id,
      COUNT(sd.id),
      MAX(sd.modified) AS modified
    FROM public.mview_latest_dataset AS sd
    GROUP BY sd.portal_id
  )
  SELECT
    p.id,
    p.name,
    p.url,
    p.description,
    ds.count AS dataset_count,
    ds.modified,
    pl.name AS platform,
    r.name AS region,
    ST_AsGeoJSON(r.geom, 6)::json AS location
  FROM public.portal AS p
  LEFT JOIN public.platform AS pl ON pl.id = p.platform_id
  LEFT JOIN public.location AS r ON r.id = p.location_id
  LEFT JOIN data_summary AS ds ON ds.portal_id = p.id;
