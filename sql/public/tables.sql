CREATE TABLE public.platform (
  id serial PRIMARY KEY,
  name text NOT NULL,
  url text NOT NULL,
  description text
);

CREATE TABLE public.location (
  id serial PRIMARY KEY,
  name text,
  continent text,
  country text,
  province text,
  region text,
  city text,
  geom geometry(Point, 4326)
);

CREATE TABLE public.portal (
  id serial PRIMARY KEY,
  name text,
  url text NOT NULL,
  description text,
  platform_id integer REFERENCES platform (id),
  location_id integer REFERENCES location(id)
);

CREATE TABLE public.junar_portal_info (
  id serial PRIMARY KEY,
  portal_id integer REFERENCES portal (id),
  api_url text NOT NULL,
  api_key text NOT NULL
);

CREATE TABLE public.dataset (
  id serial PRIMARY KEY,
  title text NOT NULL,
  identifier char(36) NOT NULL,
  issued timestamptz,
  modified timestamptz NOT NULL,
  description text,
  landing_page text NOT NULL,
  license text,
  raw json NOT NULL,
  version integer NOT NULL,
  version_period tstzrange NOT NULL
);

CREATE TABLE public.dataset_portal_xref (
  id serial PRIMARY KEY,
  dataset_id integer REFERENCES dataset (id),
  portal_id integer REFERENCES portal (id)
);

CREATE TABLE public.dataset_publisher (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE public.dataset_publisher_xref (
  id serial PRIMARY KEY,
  dataset_id integer REFERENCES dataset (id),
  dataset_publisher_id REFERENCES dataset_publisher (id)
);

CREATE TABLE public.dataset_coverage (
  id serial PRIMARY KEY,
  name text,
  geom geometry(MultiPolygon, 4326)
);

CREATE TABLE public.dataset_coverage_xref (
  id serial PRIMARY KEY,
  dataset_id integer NOT NULL REFERENCES dataset(id),
  dataset_coverage_id integer NOT NULL REFERENCES dataset_coverage(id)
);

CREATE TABLE public.dataset_distribution (
  id serial PRIMARY KEY,
  dataset_id integer NOT NULL REFERENCES dataset(id),
  title text DEFAULT 'Data File',
  format text,
  extension text,
  description text,
  access_url text,
  download_url text
);

CREATE TABLE public.dataset_keyword (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE public.dataset_keyword_xref (
  id serial PRIMARY KEY,
  dataset_id integer REFERENCES dataset (id),
  dataset_keyword_id integer REFERENCES dataset_keyword (id)
);

CREATE TABLE public.dataset_theme (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE public.dataset_theme_xref (
  id serial PRIMARY KEY,
  dataset_id integer REFERENCES dataset (id),
  dataset_themeid integer REFERENCES dataset_theme (id)
);
