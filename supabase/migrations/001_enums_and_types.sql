-- ============================================================
-- SeeMe Database Migration 001 — Enums & Types
-- ============================================================
-- Run this in Supabase SQL Editor FIRST before any other migration

-- User roles
CREATE TYPE user_role AS ENUM ('student', 'moderator', 'admin');

-- Verification workflow states
CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected', 'resubmitted');

-- Profile visibility levels
CREATE TYPE visibility_level AS ENUM ('public', 'students_only', 'hidden');

-- Supported social/contact platforms
CREATE TYPE link_platform AS ENUM (
  'phone', 'whatsapp', 'email', 'instagram', 'linkedin',
  'github', 'x', 'portfolio', 'custom'
);

-- Notification types
CREATE TYPE notification_type AS ENUM (
  'approval', 'rejection', 'profile_view', 'system', 'announcement'
);

-- Report statuses
CREATE TYPE report_status AS ENUM ('pending', 'reviewed', 'resolved', 'dismissed');

-- Account lifecycle states
CREATE TYPE account_status AS ENUM ('active', 'soft_deleted', 'purged');
