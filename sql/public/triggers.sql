CREATE OR REPLACE FUNCTION public.insert_new_dataset() RETURNS TRIGGER AS $$
  DECLARE
    coverage_id integer;
    publisher_id integer;
  BEGIN
    IF (TG_OP = 'INSERT') THEN

      SELECT id INTO NEW.id FROM dataset
      WHERE identifier = NEW.identifier
      LIMIT 1;

      -- Check if the dataset has been saved or associated with a specific
      -- data portal
      IF NEW.id IS NOT NULL AND NEW.portal_id IS NOT NULL THEN
        PERFORM 1 FROM dataset_portal_xref AS dpx
        WHERE dpx.dataset_id = NEW.id AND dpx.portal_id = NEW.portal_id

        IF NOT FOUND THEN
          INSERT INTO dataset_portal_xref (dataset_id, portal_id) VALUES
          (NEW.id, NEW.portal_id);
        END IF;

        RETURN NEW;
      END IF;

      UPDATE dataset SET version_period = tstzrange(
        lower(version_period),
        NEW.modified,
        '[)'::text
      )
      WHERE identifier = NEW.identifier AND version = NEW.version - 1;

      INSERT INTO dataset (
        title, identifier, issued, modified, description,
        landing_page, raw
        version, version_period
      ) VALUES (
        NEW.title, NEW.identifier, NEW.issued, NEW.modified, NEW.description,
        NEW.landing_page, NEW.raw,
        NEW.version,  NEW.version_period
      ) RETURNING id INTO NEW.id;

      IF NEW.publisher IS NOT NULL THEN
        SELECT id INTO publisher_id FROM dataset_publisher WHERE title = NEW.publisher;

        IF publisher_id IS NULL THEN
          INSERT INTO dataset_publisher (name) VALUES (NEW.publisher)
          RETURNING id INTO publisher_id;
        END IF;

        INSERT INTO dataset_publisher_xref (dataset_id, dataset_publisher_id) VALUES
        (NEW.id, publisher_id);
      END IF;

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

      WITH existing_keyword AS (
        SELECT id, name FROM dataset_keyword WHERE name = any(NEW.keyword)
      ), new_keyword AS (
        INSERT INTO dataset_keyword (name) (
          SELECT keyword FROM unnest(NEW.keyword) AS keyword
          WHERE keyword NOT IN (SELECT name FROM existing_keyword)
          AND keyword <> ''
        ) RETURNING id, name
      )
      INSERT INTO dataset_keyword_xref (dataset_id, dataset_keyword_id) (
        SELECT NEW.id, ek.id FROM existing_keyword AS ek
        UNION ALL
        SELECT NEW.id, nk.id FROM new_keyword AS nk
      );

      WITH existing_theme AS (
        SELECT id, name FROM dataset_theme WHERE name = any(NEW.theme)
      ), new_theme AS (
        INSERT INTO dataset_theme (name) (
          SELECT theme FROM unnest(NEW.theme) AS theme
          WHERE theme NOT IN (SELECT name FROM existing_theme)
          AND theme <> ''
        ) RETURNING id, name
      )
      INSERT INTO dataset_theme_xref (dataset_id, dataset_theme_id) (
        SELECT NEW.id, et.id FROM existing_theme AS et
        UNION ALL
        SELECT NEW.id, nt.id FROM new_theme AS nt
      );

      INSERT INTO dataset_distribution (dataset_id, title, access_url, download_url, format, description, extension) (
        SELECT
          NEW.id,
          file ->> 'title',
          file ->> 'accessURL',
          file ->> 'downloadURL',
          file ->> 'format',
          file ->> 'description',
          file ->> 'extension'
        FROM unnest(NEW.distribution) AS data(file)
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
