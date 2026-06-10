-- ============================================================
-- HERTZ PERFUMES — Shopfloor Visibility DB Schema
-- Run this once against your PostgreSQL database:
--   psql -U postgres -d hertz -f schema.sql
--
-- Safe to re-run on an existing database:
--   - Tables use CREATE TABLE IF NOT EXISTS
--   - Columns use ALTER TABLE ... ADD COLUMN IF NOT EXISTS
--   - View uses CREATE OR REPLACE VIEW
-- ============================================================

-- Production plan (uploaded by planner)
CREATE TABLE IF NOT EXISTS plan (
    id          SERIAL PRIMARY KEY,
    date        DATE NOT NULL,
    line        INTEGER NOT NULL,
    supervisor  TEXT NOT NULL,
    job_no      TEXT NOT NULL,
    product     TEXT NOT NULL,
    ml          NUMERIC(6,1) NOT NULL DEFAULT 100,
    target_qty  INTEGER NOT NULL,
    job_type    TEXT NOT NULL DEFAULT 'Filling & Packing',
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (date, line, job_no)
);

-- Actuals entered by supervisors
CREATE TABLE IF NOT EXISTS actuals (
    id              SERIAL PRIMARY KEY,
    date            DATE NOT NULL,
    line            INTEGER NOT NULL,
    job_no          TEXT NOT NULL,
    actual_qty      INTEGER,
    not_produced    BOOLEAN DEFAULT FALSE,
    period_from     TEXT,
    period_to       TEXT,
    batch_no        TEXT,
    reason          TEXT,
    remark          TEXT,
    submitted       BOOLEAN DEFAULT FALSE,
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (date, line, job_no)
);

-- Safe to re-run: adds new columns if missing from older schema
ALTER TABLE actuals ADD COLUMN IF NOT EXISTS not_produced BOOLEAN DEFAULT FALSE;
ALTER TABLE actuals ADD COLUMN IF NOT EXISTS period_from  TEXT;
ALTER TABLE actuals ADD COLUMN IF NOT EXISTS period_to    TEXT;
ALTER TABLE actuals ADD COLUMN IF NOT EXISTS reason       TEXT;

-- Add-on SKUs (supervisor initiative, not on plan)
CREATE TABLE IF NOT EXISTS actuals_addon (
    id          SERIAL PRIMARY KEY,
    date        DATE NOT NULL,
    line        INTEGER NOT NULL,
    product     TEXT NOT NULL,
    job_no      TEXT,
    ml          NUMERIC(6,1) DEFAULT 100,
    actual_qty  INTEGER NOT NULL DEFAULT 0,
    period_from TEXT,
    period_to   TEXT,
    batch_no    TEXT,
    reason      TEXT,
    remark      TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_plan_date_line    ON plan (date, line);
CREATE INDEX IF NOT EXISTS idx_actuals_date_line ON actuals (date, line);
CREATE INDEX IF NOT EXISTS idx_addon_date_line   ON actuals_addon (date, line);

-- ── REPORT VIEW ────────────────────────────────────────────────
-- Live JOIN of plan + actuals with delta calculated
-- Query: SELECT * FROM report WHERE date = '2026-04-01' ORDER BY line, job_no;
CREATE OR REPLACE VIEW report AS
SELECT
    p.date,
    p.line,
    p.supervisor,
    p.job_no,
    p.product,
    p.ml,
    p.job_type,
    p.target_qty,
    a.actual_qty,
    a.not_produced,
    COALESCE(a.actual_qty, 0) - p.target_qty                          AS delta,
    CASE
        WHEN p.target_qty = 0 THEN NULL
        ELSE ROUND(
            (COALESCE(a.actual_qty, 0) - p.target_qty)::NUMERIC
            / p.target_qty * 100, 2)
    END                                                                AS delta_pct,
    a.period_from,
    a.period_to,
    a.batch_no,
    a.reason,
    a.remark,
    a.submitted,
    a.updated_at
FROM plan p
LEFT JOIN actuals a
    ON  a.date   = p.date
    AND a.line   = p.line
    AND a.job_no = p.job_no;
