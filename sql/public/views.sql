CREATE OR REPLACE VIEW public.view_latest_dataset AS
  WITH ds as (
    SELECT DISTINCT ON (po.name, d.portal_dataset_id)
      d.id,
      d.identifier,
      d.title,
      d.portal_dataset_id,
      d.description,
      dp.name AS publisher,
      po.id AS portal_id,
      po.name AS portal,
      po.url AS portal_url,
      pl.name AS platform,
      d.landing_page,
      d.issued,
      d.modified,
      d.license,
      ST_AsGeoJSON(dc.geom, 6)::json AS spatial,
      d.version,
      d.version_period,
      d.raw
    FROM dataset AS d
    LEFT JOIN dataset_publisher_xref AS dpx ON dpx.dataset_id = d.id
    LEFT JOIN dataset_publisher dp ON dp.id = dpx.dataset_publisher_id
    LEFT JOIN dataset_portal_xref AS dpox ON dpox.dataset_id = d.id
    LEFT JOIN portal AS po ON po.id = dpox.portal_id
    LEFT JOIN platform AS pl ON pl.id = po.platform_id
    LEFT JOIN dataset_coverage_xref AS dcx ON dcx.dataset_id = d.id
    LEFT JOIN dataset_coverage AS dc ON dc.id = dcx.dataset_coverage_id
    ORDER BY po.name, d.portal_dataset_id, version DESC
  ), versions AS (
    SELECT
      d.portal_dataset_id,
      po.name AS portal,
      array_agg(json_build_object(
        'identifier', identifier,
        'version', version,
        'modified', lower(version_period)
      ) ORDER BY version DESC) AS history
    FROM dataset AS d
    LEFT JOIN dataset_portal_xref AS dpox ON dpox.dataset_id = d.id
    LEFT JOIN portal AS po ON po.id = dpox.portal_id
    GROUP BY d.portal_dataset_id, po.name
  ), dt AS (
    SELECT
      dtx.dataset_id,
      array_agg(dt.name) AS theme
    FROM ds, dataset_theme_xref AS dtx
    LEFT JOIN dataset_theme AS dt ON dt.id = dtx.dataset_theme_id
    WHERE dtx.dataset_id = ds.id
    GROUP BY dtx.dataset_id
  ), dk AS (
    SELECT
      dkx.dataset_id,
      array_agg(dk.name)AS keyword
    FROM ds, dataset_keyword_xref AS dkx
    LEFT JOIN dataset_keyword AS dk ON dk.id = dkx.dataset_keyword_id
    WHERE dkx.dataset_id = ds.id
    GROUP BY dkx.dataset_id
  ), dd AS (
    SELECT
      dataset_id,
      array_agg(json_build_object(
        'title', dd.title,
        'format', dd.format,
        'accessURL', dd.access_url,
        'downloadURL', dd.download_url,
        'description', dd.description
      )) AS distribution
    FROM ds, dataset_distribution AS dd
    WHERE dd.dataset_id = ds.id
    GROUP BY dd.dataset_id
  )
  SELECT
    ds.id,
    ds.identifier,
    ds.title,
    ds.description,
    ds.publisher,
    ds.portal_id,
    ds.portal,
    ds.portal_url,
    ds.platform,
    ds.landing_page,
    ds.issued,
    ds.modified,
    ds.license,
    ds.spatial,
    ds.version,
    ds.version_period,
    COALESCE(v.history, '{}') AS version_history,
    COALESCE(dd.distribution, '{}') AS distribution,
    COALESCE(dt.theme, '{}') AS theme,
    COALESCE(dk.keyword, '{}') AS keyword,
    ds.raw
  FROM ds
  LEFT JOIN dt ON dt.dataset_id = ds.id
  LEFT JOIN dk ON dk.dataset_id = ds.id
  LEFT JOIN dd ON dd.dataset_id = ds.id
  LEFT JOIN versions AS v ON v.portal_dataset_id = ds.portal_dataset_id AND v.portal = ds.portal;

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
