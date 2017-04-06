CREATE MATERIALIZED VIEW search_engine.view_search_table AS
  SELECT
    id AS dataset_id,
    setweight(to_tsvector(name), 'A') ||
    setweight(to_tsvector(array_to_string(tags, ',')), 'A') ||
    setweight(to_tsvector(array_to_string(categories, ',')), 'B') ||
    setweight(to_tsvector(description), 'B') AS key_words
  FROM public.view_latest_dataset;
