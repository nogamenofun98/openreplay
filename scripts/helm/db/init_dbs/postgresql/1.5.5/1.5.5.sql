BEGIN;
CREATE OR REPLACE FUNCTION openreplay_version()
    RETURNS text AS
$$
SELECT 'v1.5.5'
$$ LANGUAGE sql IMMUTABLE;


CREATE TABLE IF NOT EXISTS dashboards
(
    dashboard_id integer generated BY DEFAULT AS IDENTITY PRIMARY KEY,
    project_id   integer   NOT NULL REFERENCES projects (project_id) ON DELETE CASCADE,
    user_id      integer   NOT NULL REFERENCES users (user_id) ON DELETE SET NULL,
    name         text      NOT NULL,
    is_public    boolean   NOT NULL DEFAULT TRUE,
    is_pinned    boolean   NOT NULL DEFAULT FALSE,
    created_at   timestamp NOT NULL DEFAULT timezone('utc'::text, now()),
    deleted_at   timestamp NULL     DEFAULT NULL
);


ALTER TABLE IF EXISTS metrics
    DROP CONSTRAINT IF EXISTS null_project_id_for_template_only,
    DROP CONSTRAINT IF EXISTS unique_key;

ALTER TABLE IF EXISTS metrics
    ADD COLUMN IF NOT EXISTS edited_at     timestamp NULL     DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS is_pinned     boolean   NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS category      text      NULL     DEFAULT 'custom',
    ADD COLUMN IF NOT EXISTS is_predefined boolean   NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS is_template   boolean   NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS key           text      NULL     DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS config        jsonb     NOT NULL DEFAULT '{}'::jsonb,
    ALTER COLUMN project_id DROP NOT NULL,
    ADD CONSTRAINT null_project_id_for_template_only
        CHECK ( (metrics.category != 'custom') != (metrics.project_id IS NOT NULL) ),
    ADD CONSTRAINT unique_key UNIQUE (key);



CREATE TABLE IF NOT EXISTS dashboard_widgets
(
    widget_id    integer generated BY DEFAULT AS IDENTITY PRIMARY KEY,
    dashboard_id integer   NOT NULL REFERENCES dashboards (dashboard_id) ON DELETE CASCADE,
    metric_id    integer   NOT NULL REFERENCES metrics (metric_id) ON DELETE CASCADE,
    user_id      integer   NOT NULL REFERENCES users (user_id) ON DELETE SET NULL,
    created_at   timestamp NOT NULL DEFAULT timezone('utc'::text, now()),
    config       jsonb     NOT NULL DEFAULT '{}'::jsonb
);

COMMIT;
ALTER TYPE metric_view_type ADD VALUE IF NOT EXISTS 'areaChart';
ALTER TYPE metric_type ADD VALUE IF NOT EXISTS 'overview';

INSERT INTO metrics (name, category, config, is_predefined, is_template, is_public, key, metric_type)
VALUES ('sessions count', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'count_sessions', 'overview'),
       ('avg request load time', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_request_load_time', 'overview'),
       ('avg page load time', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_page_load_time', 'overview'),
       ('avg image load time', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_image_load_time', 'overview'),
       ('avg dom content load start', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_dom_content_load_start', 'overview'),
       ('avg first contentful pixel', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_first_contentful_pixel', 'overview'),
       ('avg visited pages count', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_visited_pages', 'overview'),
       ('avg session duration', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_session_duration', 'overview'),
       ('avg pages dom build time', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_pages_dom_buildtime', 'overview'),
       ('avg pages response time', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_pages_response_time', 'overview'),
       ('avg response time', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_response_time', 'overview'),
       ('avg first paint', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_first_paint', 'overview'),
       ('avg dom content loaded', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_dom_content_loaded', 'overview'),
       ('avg time till first bit', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_till_first_bit', 'overview'),
       ('avg time to interactive', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_time_to_interactive', 'overview'),
       ('requests count', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'count_requests', 'overview'),
       ('avg time to render', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_time_to_render', 'overview'),
       ('avg used js heap size', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_used_js_heap_size', 'overview'),
       ('avg cpu', 'overview', '{"col":1,"row":1,"position":0}', true, true, true, 'avg_cpu', 'overview')
ON CONFLICT (key) DO UPDATE SET name=excluded.name,
                                category=excluded.category,
                                config=excluded.config,
                                is_predefined=excluded.is_predefined,
                                is_template=excluded.is_template,
                                is_public=excluded.is_public,
                                metric_type=excluded.metric_type;