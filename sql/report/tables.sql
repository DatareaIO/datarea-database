CREATE TABLE report.api (
  id serial PRIMARY KEY,
  name text,
  api_url text NOT NULL
);

CREATE TABLE report.api_usage (
  id serial PRIMARY KEY,
  api_id integer NOT NULL REFERENCES report.api (id),
  time timestamptz NOT NULL,
  ip text,
  location text
);
