CREATE INDEX ON public.dataset (id);
CREATE INDEX ON public.dataset (portal_dataset_id);
CREATE INDEX ON public.dataset (portal_dataset_md5);
CREATE INDEX ON public.dataset (version_number);
CREATE INDEX ON public.portal (id);
CREATE INDEX ON public.dataset_publisher (name);
CREATE INDEX ON public.dataset_tag (name);
CREATE INDEX ON public.dataset_category (name);
CREATE INDEX ON public.dataset_region USING GIST (geom);

CREATE UNIQUE INDEX ON public.dataset (portal_id, portal_dataset_id, updated_time);
CREATE UNIQUE INDEX ON public.dataset_tag (name);
CREATE UNIQUE INDEX ON public.dataset_category (name);
CREATE UNIQUE INDEX ON public.dataset_publisher (name);
