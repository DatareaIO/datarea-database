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

CREATE TABLE public.dataset_region (
  id serial PRIMARY KEY,
  name text,
  geom geometry(MultiPolygon, 4326)
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

CREATE TABLE public.dataset_publisher (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE public.dataset (
  id serial PRIMARY KEY,
  name text NOT NULL,
  portal_dataset_id text,
  uuid char(36) NOT NULL,
  created_time timestamptz,
  updated_time timestamptz NOT NULL,
  description text,
  portal_link text NOT NULL,
  license text,
  publisher_id integer REFERENCES dataset_publisher (id),
  portal_id integer REFERENCES portal (id),
  dataset_region_id integer REFERENCES dataset_region (id),
  raw json NOT NULL,
  raw_md5 char(32) NOT NULL,
  version_number integer NOT NULL,
  version_period tstzrange NOT NULL
);

CREATE TABLE public.dataset_data (
  id serial PRIMARY KEY,
  dataset_id integer NOT NULL REFERENCES dataset(id),
  name text DEFAULT 'Data File',
  format text,
  link text NOT NULL,
  description text
);

CREATE TABLE public.dataset_tag (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE public.dataset_tag_xref (
  id serial PRIMARY KEY,
  dataset_id integer REFERENCES dataset (id),
  dataset_tag_id integer REFERENCES dataset_tag (id)
);

CREATE TABLE public.dataset_category (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE public.dataset_category_xref (
  id serial PRIMARY KEY,
  dataset_id integer REFERENCES dataset (id),
  dataset_category_id integer REFERENCES dataset_category (id)
);
