-- ============================================================
-- SeeMe Database Migration 006 — Row Level Security Policies
-- ============================================================

-- ─── Profiles ────────────────────────────────────────────────

CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles_select_public" ON profiles
  FOR SELECT USING (
    visibility IN ('public', 'students_only')
    AND is_verified = true
    AND account_status = 'active'
  );

CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (auth.uid() = id AND account_status = 'active')
  WITH CHECK (auth.uid() = id AND account_status = 'active');

CREATE POLICY "profiles_admin_all" ON profiles
  FOR ALL USING (is_admin(auth.uid()));

-- ─── User Links ──────────────────────────────────────────────

CREATE POLICY "user_links_crud_own" ON user_links
  FOR ALL USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_links_select_visible" ON user_links
  FOR SELECT USING (
    is_visible = true
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = user_links.user_id
        AND profiles.visibility IN ('public', 'students_only')
        AND profiles.is_verified = true
        AND profiles.account_status = 'active'
    )
  );

-- ─── Student Verifications ───────────────────────────────────

CREATE POLICY "verifications_insert_own" ON student_verifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "verifications_select_own" ON student_verifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "verifications_update_own_rejected" ON student_verifications
  FOR UPDATE USING (auth.uid() = user_id AND status = 'rejected')
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "verifications_moderator_admin" ON student_verifications
  FOR ALL USING (is_admin_or_moderator(auth.uid()));

-- ─── Scan History ────────────────────────────────────────────

CREATE POLICY "scan_history_insert_own" ON scan_history
  FOR INSERT WITH CHECK (auth.uid() = scanner_id);

CREATE POLICY "scan_history_select_own" ON scan_history
  FOR SELECT USING (auth.uid() = scanner_id);

CREATE POLICY "scan_history_delete_own" ON scan_history
  FOR DELETE USING (auth.uid() = scanner_id);

-- ─── Notifications ───────────────────────────────────────────

CREATE POLICY "notifications_select_own" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notifications_admin_insert" ON notifications
  FOR INSERT WITH CHECK (is_admin_or_moderator(auth.uid()) OR auth.uid() = user_id);

-- ─── Profile Views ───────────────────────────────────────────

CREATE POLICY "profile_views_insert_authenticated" ON profile_views
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = viewer_id);

CREATE POLICY "profile_views_select_own_views" ON profile_views
  FOR SELECT USING (auth.uid() = viewed_id);

-- ─── Reported Profiles ──────────────────────────────────────

CREATE POLICY "reported_profiles_insert_authenticated" ON reported_profiles
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = reporter_id);

CREATE POLICY "reported_profiles_moderator_admin" ON reported_profiles
  FOR ALL USING (is_admin_or_moderator(auth.uid()));

-- ─── Blocked Users ───────────────────────────────────────────

CREATE POLICY "blocked_users_crud_own" ON blocked_users
  FOR ALL USING (auth.uid() = blocker_id)
  WITH CHECK (auth.uid() = blocker_id);

-- ─── User Devices ────────────────────────────────────────────

CREATE POLICY "user_devices_crud_own" ON user_devices
  FOR ALL USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── App Config ──────────────────────────────────────────────

CREATE POLICY "app_config_select_authenticated" ON app_config
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "app_config_admin_manage" ON app_config
  FOR ALL USING (is_admin(auth.uid()));

-- ─── Feature Flags ───────────────────────────────────────────

CREATE POLICY "feature_flags_select_authenticated" ON feature_flags
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "feature_flags_admin_manage" ON feature_flags
  FOR ALL USING (is_admin(auth.uid()));

-- ─── Activity Logs ───────────────────────────────────────────

CREATE POLICY "activity_logs_insert_authenticated" ON activity_logs
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "activity_logs_admin_read" ON activity_logs
  FOR SELECT USING (is_admin(auth.uid()));

-- ─── Audit Logs ──────────────────────────────────────────────

CREATE POLICY "audit_logs_admin_only" ON audit_logs
  FOR ALL USING (is_admin(auth.uid()));

-- ─── Rate Limit Events ──────────────────────────────────────

CREATE POLICY "rate_limit_events_insert_authenticated" ON rate_limit_events
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "rate_limit_events_select_own" ON rate_limit_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "rate_limit_events_admin_read" ON rate_limit_events
  FOR SELECT USING (is_admin(auth.uid()));

-- ─── App Versions ────────────────────────────────────────────

CREATE POLICY "app_versions_select_authenticated" ON app_versions
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "app_versions_admin_manage" ON app_versions
  FOR ALL USING (is_admin(auth.uid()));
