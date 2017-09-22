CREATE MATERIALIZED VIEW public.mview_latest_dataset AS
  SELECT
    view_latest_dataset.id,
    view_latest_dataset.identifier,
    view_latest_dataset.title,
    view_latest_dataset.description,
    view_latest_dataset.publisher,
    view_latest_dataset.portal_id,
    view_latest_dataset.portal,
    view_latest_dataset.portal_url,
    view_latest_dataset.platform,
    view_latest_dataset.landing_page,
    view_latest_dataset.issued,
    view_latest_dataset.modified,
    view_latest_dataset.license,
    view_latest_dataset.spatial,
    view_latest_dataset.version,
    view_latest_dataset.version_period,
    view_latest_dataset.version_history,
    view_latest_dataset.distribution,
    view_latest_dataset.keyword,
    view_latest_dataset.theme
  FROM view_latest_dataset
  WITH DATA;

CREATE MATERIALIZED VIEW public.mview_portal AS
  WITH data_summary AS (
    SELECT
      sd.portal_id,
      COUNT(sd.portal_id),
      MAX(sd.modified) AS modified
    FROM (
      SELECT DISTINCT ON (dpx.portal_id, d.identifier)
        d.identifier,
        dpx.portal_id,
        d.modified
      FROM dataset_portal_xref AS dpx
      LEFT JOIN dataset AS d ON dpx.dataset_id = d.id
      ORDER BY d.portal_id, d.identifier, d.version DESC
    ) sd
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
