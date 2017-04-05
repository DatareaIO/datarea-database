CREATE INDEX ON public.dataset (updated_time);
CREATE INDEX ON public.dataset (portal_dataset_id);
CREATE UNIQUE INDEX ON public.dataset (portal_id, portal_dataset_id, updated_time);
CREATE UNIQUE INDEX ON public.dataset_tag (name);
CREATE UNIQUE INDEX ON public.dataset_category (name);
CREATE UNIQUE INDEX ON public.dataset_publisher (name);
