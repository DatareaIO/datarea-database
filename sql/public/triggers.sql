CREATE OR REPLACE FUNCTION public.insert_new_dataset() RETURNS TRIGGER AS $$
  DECLARE
    coverage_id integer;
    publisher_id integer;
  BEGIN
    IF (TG_OP = 'INSERT') THEN

      PERFORM id FROM dataset
      WHERE portal_id = NEW.portal_id AND
            portal_dataset_id = NEW.portal_dataset_id AND
            version = NEW.version
      LIMIT 1;

      IF FOUND THEN
        RETURN NEW;
      END IF;

      SELECT id INTO publisher_id FROM dataset_publisher WHERE name = NEW.publisher LIMIT 1;

      IF NOT FOUND THEN
        INSERT INTO dataset_publisher (name) VALUES (NEW.publisher)
        RETURNING id INTO publisher_id;
      END IF;

      UPDATE dataset SET version_period = tstzrange(
        lower(version_period),
        NEW.updated,
        '[)'::text
      )
      WHERE portal_dataset_id = NEW.portal_dataset_id AND
            portal_id = NEW.portal_id AND
            version = NEW.version - 1;

      INSERT INTO dataset (
        name, portal_dataset_id, uuid, created, updated, description,
        url, publisher_id, portal_id, raw, raw_md5,
        version, version_period
      ) VALUES (
        NEW.name, NEW.portal_dataset_id, NEW.uuid, NEW.created, NEW.updated, NEW.description,
        NEW.url, publisher_id, NEW.portal_id, NEW.raw, md5(NEW.raw::text),
        NEW.version,  NEW.version_period
      ) RETURNING id INTO NEW.id;

      IF NEW.spatial IS NOT NULL THEN
        SELECT id INTO coverage_id FROM dataset_coverage
        WHERE ST_Equals(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(NEW.spatial::text)), 4326), geom) LIMIT 1;

        IF NOT FOUND THEN
          INSERT INTO dataset_coverage (geom) VALUES (ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(NEW.spatial::text)), 4326))
          RETURNING id INTO coverage_id;

          INSERT INTO dataset_coverage_xref (dataset_id, dataset_coverage_id) VALUES
          (NEW.id, coverage_id);
        END IF;
      END IF;

      WITH existing_tags AS (
        SELECT id, name FROM dataset_tag WHERE name = any(NEW.tags)
      ), new_tags AS (
        INSERT INTO dataset_tag (name) (
          SELECT tag FROM unnest(NEW.tags) AS tag
          WHERE tag NOT IN (SELECT name FROM existing_tags)
          AND tag <> ''
        ) RETURNING id, name
      )
      INSERT INTO dataset_tag_xref (dataset_id, dataset_tag_id) (
        SELECT NEW.id, id FROM existing_tags
        UNION ALL
        SELECT NEW.id, id FROM new_tags
      );

      WITH existing_categories AS (
        SELECT id, name FROM dataset_category WHERE name = any(NEW.categories)
      ), new_categories AS (
        INSERT INTO dataset_category (name) (
          SELECT category FROM unnest(NEW.categories) AS category
          WHERE category NOT IN (SELECT name FROM existing_categories)
          AND category <> ''
        ) RETURNING id, name
      )
      INSERT INTO dataset_category_xref (dataset_id, dataset_category_id) (
        SELECT NEW.id, id FROM existing_categories
        UNION ALL
        SELECT NEW.id, id FROM new_categories
      );

      INSERT INTO dataset_file (dataset_id, name, url, format, description, extension) (
        SELECT
          NEW.id,
          file ->> 'name',
          file ->> 'url',
          file ->> 'format',
          file ->> 'description',
          file ->> 'extension'
        FROM unnest(NEW.files) AS data(file)
      );

      RETURN NEW;
    END IF;
  END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_new_dataset
INSTEAD OF INSERT
ON public.view_latest_dataset
FOR EACH ROW
EXECUTE PROCEDURE public.insert_new_dataset();

CREATE OR REPLACE FUNCTION public.insert_new_portal() RETURNS TRIGGER AS $$
  DECLARE
    location_id integer;
    platform_id integer;
  BEGIN
    IF (TG_OP = 'INSERT') THEN

      SELECT id INTO platform_id FROM platform WHERE name = NEW.platform LIMIT 1;

      SELECT id INTO location_id FROM location WHERE name = NEW.location_name LIMIT 1;

      IF NOT FOUND AND NEW.location IS NOT NULL THEN
        INSERT INTO location (geom)
        VALUES (ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(NEW.location::text)), 4326))
        RETURNING id INTO location_id;
      END IF;

      INSERT INTO portal (name, url, description, platform_id, location_id)
      VALUES (NEW.name, NEW.url, NEW.description, platform_id, location_id);

      RETURN NEW;
    END IF;
  END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_new_portal
INSTEAD OF INSERT
ON public.view_portal
FOR EACH ROW
EXECUTE PROCEDURE public.insert_new_portal();
