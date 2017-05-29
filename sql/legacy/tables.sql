CREATE TABLE legacy.portal_history (
  id serial PRIMARY KEY,
  portal_id integer REFERENCES public.portal(id),
  period tstzrange NOT NULL,
  dataset_count integer NOT NULL,
  tags json[] DEFAULT '{}',
  categories json[] DEFAULT '{}',
  publishers json[] DEFAULT '{}'
);
