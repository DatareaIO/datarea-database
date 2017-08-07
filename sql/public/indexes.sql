/**
 * Table indexes
 */
CREATE INDEX ON public.dataset (id);
CREATE INDEX ON public.dataset (portal_dataset_id);
CREATE INDEX ON public.dataset (uuid);
CREATE INDEX ON public.dataset (version);
CREATE INDEX ON public.portal (id);
CREATE INDEX ON public.dataset_publisher (name);
CREATE INDEX ON public.dataset_tag_xref(dataset_id);
CREATE INDEX ON public.dataset_tag (name);
CREATE INDEX ON public.dataset_category_xref(dataset_id);
CREATE INDEX ON public.dataset_category (name);
CREATE INDEX ON public.dataset_file (dataset_id);
CREATE INDEX ON public.dataset_region USING GIST (geom);

/**
 * Table unique indexes
 */
CREATE UNIQUE INDEX ON public.dataset (portal_id, portal_dataset_id, version);
CREATE UNIQUE INDEX ON public.dataset (raw_md5);
CREATE UNIQUE INDEX ON public.dataset_tag (name);
CREATE UNIQUE INDEX ON public.dataset_category (name);
CREATE UNIQUE INDEX ON public.dataset_publisher (name);

/**
 * Materialized view indexes
 */
CREATE INDEX ON public.mview_latest_dataset (uuid);

/**
 * Materialized view unique indexes
 */
CREATE UNIQUE INDEX ON public.mview_latest_dataset (id);
CREATE UNIQUE INDEX ON public.mview_portal (id);
