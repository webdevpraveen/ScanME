-- ============================================================
-- SeeMe Database Migration 008 — Seed Data
-- ============================================================

-- ─── App Config Defaults ─────────────────────────────────────

INSERT INTO app_config (key, value, description) VALUES
  ('maintenance_mode', 'false', 'Enable/disable maintenance mode'),
  ('minimum_app_version', '"1.0.0"', 'Minimum supported app version'),
  ('latest_app_version', '"1.0.0"', 'Latest available app version'),
  ('support_email', '""', 'Support contact email'),
  ('support_whatsapp', '""', 'Support WhatsApp number'),
  ('announcement_text', 'null', 'Global announcement banner text'),
  ('max_scans_per_hour', '100', 'Rate limit: max QR scans per hour per user'),
  ('max_profile_views_per_hour', '300', 'Rate limit: max profile views per hour per user'),
  ('max_searches_per_hour', '200', 'Rate limit: max searches per hour per user'),
  ('account_deletion_recovery_days', '30', 'Days before soft-deleted accounts are permanently purged'),
  ('scan_history_retention_days', '180', 'Days to retain scan history before cleanup'),
  ('activity_log_retention_days', '365', 'Days to retain activity logs'),
  ('audit_log_retention_days', '365', 'Days to retain audit logs')
ON CONFLICT (key) DO NOTHING;

-- ─── Feature Flags Defaults ──────────────────────────────────

INSERT INTO feature_flags (name, is_enabled, description) VALUES
  ('search_enabled', true, 'Enable user search and discovery'),
  ('notifications_enabled', true, 'Enable push notifications'),
  ('profile_views_tracking', true, 'Track and display profile view counts'),
  ('multi_college', false, 'Multi-college support'),
  ('account_deletion', true, 'Allow users to request account deletion'),
  ('re_verification', true, 'Allow rejected students to resubmit verification'),
  ('qr_fallback_search', true, 'Show search fallback when QR scan fails'),
  ('moderator_dashboard', true, 'Enable moderator dashboard'),
  ('admin_dashboard', true, 'Enable admin dashboard'),
  ('analytics_tracking', true, 'Enable Firebase Analytics event tracking')
ON CONFLICT (name) DO NOTHING;
