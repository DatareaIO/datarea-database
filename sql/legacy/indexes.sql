CREATE INDEX ON legacy.portal_history (portal_id);
CREATE INDEX ON legacy.portal_history USING gist (period);
