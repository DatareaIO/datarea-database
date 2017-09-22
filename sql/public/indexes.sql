/**
 * Table indexes
 */
CREATE INDEX ON public.dataset (id);
CREATE INDEX ON public.dataset (identifier);
CREATE INDEX ON public.dataset (version);
CREATE INDEX ON public.portal (id);
CREATE INDEX ON public.dataset_publisher (name);
CREATE INDEX ON public.dataset_keyword_xref(dataset_id);
CREATE INDEX ON public.dataset_keyword (name);
CREATE INDEX ON public.dataset_theme_xref(dataset_id);
CREATE INDEX ON public.dataset_theme (name);
CREATE INDEX ON public.dataset_distribution (dataset_id);
CREATE INDEX ON public.dataset_coverage USING GIST (geom);

/**
 * Table unique indexes
 */
CREATE UNIQUE INDEX ON public.dataset_keyword (name);
CREATE UNIQUE INDEX ON public.dataset_theme (name);
CREATE UNIQUE INDEX ON public.dataset_publisher (name);

/**
 * Materialized view indexes
 */
CREATE INDEX ON public.mview_latest_dataset (identifier);

/**
 * Materialized view unique indexes
 */
CREATE UNIQUE INDEX ON public.mview_latest_dataset (id);
CREATE UNIQUE INDEX ON public.mview_portal (id);
