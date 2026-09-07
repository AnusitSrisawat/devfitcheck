-- DevFitCheck — PostgreSQL Schema (Phase 1)
-- Run this against a fresh database to create all tables for the MVP.

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================================
-- USERS & AUTH
-- =========================================

CREATE TYPE user_role AS ENUM ('developer', 'company');

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         VARCHAR(255) UNIQUE,
    phone         VARCHAR(32) UNIQUE,
    password_hash TEXT,                     -- nullable: OAuth-only users won't have one
    role          user_role NOT NULL,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT users_email_or_phone_required CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

CREATE TYPE auth_provider_type AS ENUM ('email', 'phone', 'google');

CREATE TABLE auth_providers (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider      auth_provider_type NOT NULL,
    provider_uid  VARCHAR(255) NOT NULL,     -- e.g. Google's "sub" claim
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, provider_uid)
);

CREATE TABLE otp_codes (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destination   VARCHAR(255) NOT NULL,     -- phone number or email the OTP was sent to
    code_hash     TEXT NOT NULL,             -- never store the raw OTP
    purpose       VARCHAR(32) NOT NULL,      -- 'login', 'verify_phone', etc.
    expires_at    TIMESTAMPTZ NOT NULL,
    verified_at   TIMESTAMPTZ,
    attempt_count INT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_otp_codes_destination ON otp_codes(destination);

-- =========================================
-- DEVELOPER PROFILE
-- =========================================

CREATE TABLE developer_profiles (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name            VARCHAR(255) NOT NULL,
    headline             VARCHAR(255),        -- e.g. "Backend Developer, 3 yrs"
    bio                  TEXT,
    avatar_url           TEXT,
    resume_url           TEXT,
    github_url           TEXT,
    linkedin_url         TEXT,
    portfolio_url        TEXT,
    years_of_experience  NUMERIC(4,1),
    expected_salary_min  INT,
    expected_salary_max  INT,
    is_open_to_work      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE work_experiences (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    developer_id  UUID NOT NULL REFERENCES developer_profiles(id) ON DELETE CASCADE,
    company_name  VARCHAR(255) NOT NULL,
    job_title     VARCHAR(255) NOT NULL,
    description   TEXT,
    start_date    DATE NOT NULL,
    end_date      DATE,                       -- null = still working there
    is_current    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_work_experiences_developer_id ON work_experiences(developer_id);

-- =========================================
-- COMPANY PROFILE
-- =========================================

CREATE TABLE company_profiles (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    company_name  VARCHAR(255) NOT NULL,
    description   TEXT,
    website_url   TEXT,
    logo_url      TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================
-- TECH STACKS (master list, find-or-create pattern)
-- =========================================

CREATE TABLE tech_stacks (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(100) NOT NULL,
    slug         VARCHAR(100) NOT NULL UNIQUE,   -- normalized: lowercase, no spaces
    usage_count  INT NOT NULL DEFAULT 0,          -- incremented/decremented on link/unlink
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE developer_tech_stacks (
    developer_id   UUID NOT NULL REFERENCES developer_profiles(id) ON DELETE CASCADE,
    tech_stack_id  UUID NOT NULL REFERENCES tech_stacks(id) ON DELETE CASCADE,
    proficiency    VARCHAR(20),   -- 'beginner' | 'intermediate' | 'expert'
    PRIMARY KEY (developer_id, tech_stack_id)
);

-- =========================================
-- BENEFITS (master list, find-or-create pattern, same idea as tech_stacks)
-- =========================================

CREATE TABLE benefits (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    slug        VARCHAR(100) NOT NULL UNIQUE,
    category    VARCHAR(50),          -- 'leave' | 'insurance' | 'perks' | etc.
    is_common   BOOLEAN NOT NULL DEFAULT FALSE,  -- flagged for the quick-pick checklist
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================
-- JOBS
-- =========================================

CREATE TYPE employment_type AS ENUM ('full_time', 'part_time', 'contract', 'internship');
CREATE TYPE work_location_type AS ENUM ('onsite', 'hybrid', 'remote');
CREATE TYPE job_status AS ENUM ('open', 'closed', 'draft');

CREATE TABLE jobs (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id           UUID NOT NULL REFERENCES company_profiles(id) ON DELETE CASCADE,
    title                VARCHAR(255) NOT NULL,
    description          TEXT,
    responsibilities     TEXT[],              -- list of duty descriptions
    requirements         TEXT,
    employment_type      employment_type NOT NULL DEFAULT 'full_time',
    work_location_type   work_location_type NOT NULL DEFAULT 'onsite',
    work_days_per_week   INT,
    salary_min           INT,
    salary_max           INT,
    salary_visible        BOOLEAN NOT NULL DEFAULT TRUE,
    location             VARCHAR(255),
    status               job_status NOT NULL DEFAULT 'open',
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_jobs_company_id ON jobs(company_id);
CREATE INDEX idx_jobs_status ON jobs(status);

CREATE TABLE job_tech_stacks (
    job_id         UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    tech_stack_id  UUID NOT NULL REFERENCES tech_stacks(id) ON DELETE CASCADE,
    is_required    BOOLEAN NOT NULL DEFAULT TRUE,  -- required vs nice-to-have
    PRIMARY KEY (job_id, tech_stack_id)
);

CREATE TABLE job_benefits (
    job_id      UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    benefit_id  UUID NOT NULL REFERENCES benefits(id) ON DELETE CASCADE,
    PRIMARY KEY (job_id, benefit_id)
);

-- =========================================
-- APPLICATIONS
-- =========================================

CREATE TYPE application_status AS ENUM ('pending', 'reviewed', 'accepted', 'rejected');

CREATE TABLE applications (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id        UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    developer_id  UUID NOT NULL REFERENCES developer_profiles(id) ON DELETE CASCADE,
    status        application_status NOT NULL DEFAULT 'pending',
    match_score   INT,                 -- filled in later by the Go matching engine (Phase 2)
    cover_letter  TEXT,
    applied_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (job_id, developer_id)      -- prevent duplicate applications
);

CREATE INDEX idx_applications_job_id ON applications(job_id);
CREATE INDEX idx_applications_developer_id ON applications(developer_id);

-- =========================================
-- SEED DATA — common benefits (starter checklist for companies)
-- =========================================

INSERT INTO benefits (name, slug, category, is_common) VALUES
    ('Social Security',        'social-security',       'insurance', TRUE),
    ('Health Insurance',       'health-insurance',       'insurance', TRUE),
    ('Annual Leave',           'annual-leave',            'leave',     TRUE),
    ('Sick Leave',             'sick-leave',              'leave',     TRUE),
    ('Overtime Pay (OT)',      'overtime-pay',            'perks',     TRUE),
    ('Provident Fund',         'provident-fund',          'insurance', TRUE),
    ('Work From Home',         'work-from-home',          'perks',     TRUE),
    ('Annual Bonus',           'annual-bonus',            'perks',     TRUE),
    ('Training Budget',        'training-budget',         'perks',     FALSE),
    ('Wellness Allowance',     'wellness-allowance',      'perks',     FALSE); 