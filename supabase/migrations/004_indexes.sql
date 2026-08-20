-- ============================================================
-- SeeMe Database Migration 004 — Indexes
-- ============================================================

-- Profiles
CREATE UNIQUE INDEX idx_profiles_roll_number ON profiles(roll_number);
CREATE UNIQUE INDEX idx_profiles_seeme_qr_id ON profiles(seeme_qr_id);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_account_status ON profiles(account_status);
CREATE INDEX idx_profiles_is_verified ON profiles(is_verified);
CREATE INDEX idx_profiles_search ON profiles USING gin(search_vector);

-- User Links
CREATE INDEX idx_user_links_user ON user_links(user_id);
CREATE INDEX idx_user_links_user_platform ON user_links(user_id, platform);

-- Student Verifications
CREATE INDEX idx_verifications_status ON student_verifications(status, created_at);
CREATE INDEX idx_verifications_user ON student_verifications(user_id);

-- Scan History
CREATE INDEX idx_scan_history_scanner ON scan_history(scanner_id, created_at DESC);
CREATE INDEX idx_scan_history_scanned ON scan_history(scanned_id);
CREATE INDEX idx_scan_history_expires ON scan_history(expires_at);

-- Notifications
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);

-- Profile Views
CREATE INDEX idx_profile_views_viewed ON profile_views(viewed_id, created_at DESC);
CREATE INDEX idx_profile_views_viewer ON profile_views(viewer_id);
CREATE INDEX idx_profile_views_expires ON profile_views(expires_at);

-- Reported Profiles
CREATE INDEX idx_reported_profiles_status ON reported_profiles(status);

-- Blocked Users
CREATE INDEX idx_blocked_users_blocker ON blocked_users(blocker_id);
CREATE INDEX idx_blocked_users_blocked ON blocked_users(blocked_id);

-- User Devices
CREATE INDEX idx_user_devices_user ON user_devices(user_id);

-- Rate Limit Events
CREATE INDEX idx_rate_limit_events ON rate_limit_events(user_id, action_type, created_at DESC);

-- Activity & Audit Logs
CREATE INDEX idx_activity_logs_user ON activity_logs(user_id, created_at DESC);
CREATE INDEX idx_activity_logs_expires ON activity_logs(expires_at);
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_id, created_at DESC);
CREATE INDEX idx_audit_logs_expires ON audit_logs(expires_at);

-- App Config
CREATE UNIQUE INDEX idx_app_config_key ON app_config(key);

-- Feature Flags
CREATE UNIQUE INDEX idx_feature_flags_name ON feature_flags(name);
