/**
 * Table indexes
 */
CREATE INDEX ON public.dataset (id);
CREATE INDEX ON public.dataset (portal_dataset_id);
CREATE INDEX ON public.dataset (identifier);
CREATE INDEX ON public.dataset (version);
CREATE INDEX ON public.dataset_portal_xref (dataset_id);
CREATE INDEX ON public.dataset_publisher_xref (dataset_id);
CREATE INDEX ON public.dataset_keyword_xref(dataset_id);
CREATE INDEX ON public.dataset_theme_xref(dataset_id);
CREATE INDEX ON public.dataset_distribution (dataset_id);

/**
 * Table unique indexes
 */
CREATE UNIQUE INDEX ON public.dataset_keyword (name);
CREATE UNIQUE INDEX ON public.dataset_theme (name);
CREATE UNIQUE INDEX ON public.dataset_publisher (name);
