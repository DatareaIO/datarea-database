CREATE OR REPLACE VIEW public.view_latest_dataset AS
  WITH ds as (
    SELECT DISTINCT ON (uuid)
      d.id,
      d.uuid,
      d.name,
      d.description,
      d.portal_dataset_id,
      p.name AS publisher,
      po.id AS portal_id,
      po.name AS portal,
      po.url AS portal_url,
      pl.name AS platform,
      d.url,
      d.created,
      d.updated,
      d.license,
      ST_AsGeoJSON(dc.geom, 6)::json AS spatial,
      d.version,
      d.version_period,
      d.raw
    FROM dataset AS d
    LEFT JOIN dataset_publisher p ON p.id = d.publisher_id
    LEFT JOIN portal AS po ON po.id = d.portal_id
    LEFT JOIN platform AS pl ON pl.id = po.platform_id
    LEFT JOIN dataset_coverage_xref AS dcx ON dcx.dataset_id = d.id
    LEFT JOIN dataset_coverage AS dc ON dc.id = dcx.dataset_coverage_id
    ORDER BY uuid, version DESC
  ), versions AS (
    SELECT
      uuid,
      array_agg(json_build_object(
        'version', version,
        'updated', lower(version_period)
      ) ORDER BY version DESC) AS all
    FROM dataset
    GROUP BY uuid
  ), dc AS (
    SELECT
      dcx.dataset_id,
      array_agg(dc.name) AS categories
    FROM ds, dataset_category_xref AS dcx
    LEFT JOIN dataset_category AS dc ON dc.id = dcx.dataset_category_id
    WHERE dcx.dataset_id = ds.id
    GROUP BY dcx.dataset_id
  ), dt AS (
    SELECT
      dtx.dataset_id,
      array_agg(dt.name)AS tags
    FROM ds, dataset_tag_xref AS dtx
    LEFT JOIN dataset_tag AS dt ON dt.id = dtx.dataset_tag_id
    WHERE dtx.dataset_id = ds.id
    GROUP BY dtx.dataset_id
  ), df AS (
    SELECT
      dataset_id,
      array_agg(json_build_object(
        'name', df.name,
        'format', df.format,
        'url', df.url,
        'description', df.description
      )) AS files
    FROM ds, dataset_file AS df
    WHERE df.dataset_id = ds.id
    GROUP BY df.dataset_id
  )
  SELECT
    ds.id,
    ds.uuid,
    ds.name,
    ds.description,
    ds.publisher,
    ds.portal_id,
    ds.portal,
    ds.portal_url,
    ds.portal_dataset_id,
    ds.platform,
    ds.url,
    ds.created,
    ds.updated,
    ds.license,
    ds.spatial,
    ds.version,
    ds.version_period,
    COALESCE(v.all, '{}') AS version_history,
    COALESCE(df.files, '{}') AS files,
    COALESCE(dt.tags, '{}') AS tags,
    COALESCE(dc.categories, '{}') AS categories,
    ds.raw
  FROM ds
  LEFT JOIN dt ON dt.dataset_id = ds.id
  LEFT JOIN dc ON dc.dataset_id = ds.id
  LEFT JOIN df ON df.dataset_id = ds.id
  LEFT JOIN versions AS v ON v.uuid = ds.uuid;

CREATE OR REPLACE VIEW public.view_portal AS
  SELECT
    p.id,
    p.name,
    p.url,
    p.description,
    pl.name AS platform,
    l.name AS location_name,
    ST_AsGeoJSON(l.geom, 6)::json AS location
  FROM portal AS p
  LEFT JOIN platform AS pl ON pl.id = p.platform_id
  LEFT JOIN location AS l ON l.id = p.location_id;
