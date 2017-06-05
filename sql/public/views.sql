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
      d.portal_link,
      d.created_time,
      d.updated_time,
      d.license,
      dr.name AS region_name,
      dr.geom AS  region,
      d.version_number,
      d.version_period,
      d.raw
    FROM dataset AS d
    LEFT JOIN dataset_publisher p ON p.id = d.publisher_id
    LEFT JOIN portal AS po ON po.id = d.portal_id
    LEFT JOIN platform AS pl ON pl.id = po.platform_id
    LEFT JOIN dataset_region AS dr ON dr.id = d.dataset_region_id
    ORDER BY uuid, version_number DESC
  ), versions AS (
    SELECT
      uuid,
      array_agg(json_build_object(
        'version', version_number,
        'updatedTime', lower(version_period)
      ) ORDER BY version_number DESC) AS all
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
  ), dd AS (
    SELECT
      dataset_id,
      array_agg(json_build_object(
        'name', dd.name,
        'format', dd.format,
        'link', dd.link,
        'description', dd.description
      )) AS data
    FROM ds, dataset_data AS dd
    WHERE dd.dataset_id = ds.id
    GROUP BY dd.dataset_id
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
    ds.portal_link,
    ds.created_time,
    ds.updated_time,
    ds.license,
    ds.region_name,
    ds.region,
    ds.version_number,
    ds.version_period,
    COALESCE(v.all, '{}') AS version_history,
    COALESCE(dd.data, '{}') AS data,
    COALESCE(dt.tags, '{}') AS tags,
    COALESCE(dc.categories, '{}') AS categories,
    ds.raw
  FROM ds
  LEFT JOIN dt ON dt.dataset_id = ds.id
  LEFT JOIN dc ON dc.dataset_id = ds.id
  LEFT JOIN dd ON dd.dataset_id = ds.id
  LEFT JOIN versions AS v ON v.uuid = ds.uuid;
