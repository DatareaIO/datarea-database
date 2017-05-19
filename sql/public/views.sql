CREATE OR REPLACE VIEW public.view_latest_dataset AS
  WITH latest AS (
    SELECT DISTINCT ON (portal_id, portal_dataset_id) id
    FROM dataset
    ORDER BY portal_id, portal_dataset_id, version_number DESC
  ), latest_tag AS (
    SELECT
      dtx.dataset_id,
      array_agg(t.name) AS tags
    FROM dataset_tag_xref AS dtx
    INNER JOIN latest AS l ON l.id = dtx.dataset_id
    LEFT JOIN dataset_tag AS t ON t.id = dtx.dataset_tag_id
    GROUP BY dtx.dataset_id
  ), latest_category AS (
    SELECT
      dcx.dataset_id,
      array_agg(c.name) AS categories
    FROM dataset_category_xref AS dcx
    INNER JOIN latest AS l ON l.id = dcx.dataset_id
    LEFT JOIN dataset_category AS c ON c.id = dcx.dataset_category_id
    GROUP BY dcx.dataset_id
  )
  SELECT
    d.id,
    d.portal_id,
    d.portal_dataset_id,
    d.name,
    d.created_time,
    d.updated_time,
    d.description,
    d.portal_link,
    d.license,
    p.name AS publisher,
    lt.tags,
    lc.categories,
    d.raw,
    dr.geom AS region,
    d.version_number,
    d.version_period,
    COALESCE(ld.data,  '{}') AS data
  FROM dataset AS d
  INNER JOIN latest AS l ON l.id = d.id
  LEFT JOIN dataset_publisher AS p ON p.id = d.publisher_id
  LEFT JOIN latest_tag AS lt ON lt.dataset_id = d.id
  LEFT JOIN latest_category AS lc ON lc.dataset_id = d.id
  LEFT JOIN dataset_region AS dr ON dr.id = d.dataset_region_id
  LEFT JOIN (
    SELECT
      dd.dataset_id,
      array_agg(json_build_object(
        'name', dd.name,
        'link', dd.link,
        'format', dd.format
      )) AS data
    FROM latest, dataset_data AS dd
    WHERE latest.id = dd.dataset_id
    GROUP BY dd.dataset_id
  ) AS ld ON ld.dataset_id = d.id;
