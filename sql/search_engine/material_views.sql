CREATE MATERIALIZED VIEW search_engine.view_search_table AS
  SELECT
    id AS dataset_id,
    setweight(to_tsvector('english', name), 'A') ||
    setweight(to_tsvector('english', array_to_string(tags, ',')), 'A') ||
    setweight(to_tsvector('english', array_to_string(categories, ',')), 'D') ||
    setweight(to_tsvector('english', description), 'C') AS keywords
  FROM public.view_latest_dataset;
