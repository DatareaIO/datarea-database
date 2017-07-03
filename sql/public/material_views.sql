CREATE MATERIALIZED VIEW public.mview_latest_dataset AS
  SELECT
    view_latest_dataset.id,
    view_latest_dataset.uuid,
    view_latest_dataset.name,
    view_latest_dataset.description,
    view_latest_dataset.publisher,
    view_latest_dataset.portal_id,
    view_latest_dataset.portal,
    view_latest_dataset.portal_url,
    view_latest_dataset.portal_dataset_id,
    view_latest_dataset.platform,
    view_latest_dataset.url,
    view_latest_dataset.created,
    view_latest_dataset.updated,
    view_latest_dataset.license,
    view_latest_dataset.region_name,
    view_latest_dataset.region,
    view_latest_dataset.version,
    view_latest_dataset.version_period,
    view_latest_dataset.version_history,
    view_latest_dataset.files,
    view_latest_dataset.tags,
    view_latest_dataset.categories
  FROM view_latest_dataset
  WITH DATA;

CREATE MATERIALIZED VIEW public.mview_portal AS
  WITH data_summary AS (
    SELECT
      sd.portal_id,
      COUNT(sd.portal_dataset_id),
      MAX(sd.updated) AS updated
    FROM (
      SELECT DISTINCT ON (d.portal_id, d.portal_dataset_id)
        d.portal_dataset_id,
        d.portal_id,
        d.updated
      FROM public.dataset AS d
      ORDER BY d.portal_id, d.portal_dataset_id, d.version DESC
    ) sd
    GROUP BY sd.portal_id
  )
  SELECT
    p.id,
    p.name,
    p.url,
    p.description,
    ds.count AS dataset_count,
    ds.updated,
    pl.name AS platform,
    r.name AS region,
    ST_AsGeoJSON(r.geom, 6)::json AS location
  FROM public.portal AS p
  LEFT JOIN public.platform AS pl ON pl.id = p.platform_id
  LEFT JOIN public.location AS r ON r.id = p.location_id
  LEFT JOIN data_summary AS ds ON ds.portal_id = p.id;
