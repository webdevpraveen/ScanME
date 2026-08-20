-- ============================================================
-- SeeMe Database Migration 005 — Functions & Triggers
-- ============================================================

-- ─── Role Check Functions ────────────────────────────────────

CREATE OR REPLACE FUNCTION get_user_role(uid UUID)
RETURNS user_role AS $$
  SELECT role FROM profiles WHERE id = uid;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_admin(uid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = uid AND role = 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_moderator(uid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = uid AND role = 'moderator');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_admin_or_moderator(uid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = uid AND role IN ('admin', 'moderator'));
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─── Profile Completion Calculator ───────────────────────────

CREATE OR REPLACE FUNCTION calculate_profile_completion(uid UUID)
RETURNS INTEGER AS $$
DECLARE
  score INTEGER := 0;
  p profiles%ROWTYPE;
  link_count INTEGER;
BEGIN
  SELECT * INTO p FROM profiles WHERE id = uid;
  IF NOT FOUND THEN RETURN 0; END IF;

  -- Base fields (10 each)
  IF p.full_name IS NOT NULL AND p.full_name != '' THEN score := score + 10; END IF;
  IF p.email IS NOT NULL AND p.email != '' THEN score := score + 10; END IF;
  IF p.roll_number IS NOT NULL AND p.roll_number != '' THEN score := score + 10; END IF;
  IF p.department IS NOT NULL AND p.department != '' THEN score := score + 10; END IF;
  IF p.academic_year IS NOT NULL AND p.academic_year != '' THEN score := score + 5; END IF;
  IF p.bio IS NOT NULL AND p.bio != '' THEN score := score + 15; END IF;
  IF p.avatar_url IS NOT NULL AND p.avatar_url != '' THEN score := score + 15; END IF;
  IF array_length(p.skills, 1) IS NOT NULL AND array_length(p.skills, 1) > 0 THEN score := score + 10; END IF;
  IF array_length(p.interests, 1) IS NOT NULL AND array_length(p.interests, 1) > 0 THEN score := score + 5; END IF;

  -- Social links (10 points if at least one)
  SELECT COUNT(*) INTO link_count FROM user_links WHERE user_id = uid AND is_visible = true;
  IF link_count > 0 THEN score := score + 10; END IF;

  RETURN LEAST(score, 100);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ─── Handle New User (Trigger) ───────────────────────────────
-- Creates a profile stub when a new auth.users row is inserted

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_qr_id TEXT;
  meta_roll_number TEXT;
BEGIN
  new_qr_id := gen_random_uuid()::text;
  
  -- Extract roll_number from meta data if passed during signup
  meta_roll_number := NEW.raw_user_meta_data->>'roll_number';

  IF meta_roll_number IS NULL OR length(meta_roll_number) = 0 THEN
    -- In production, registration should ensure it's provided.
    meta_roll_number := '000000000000000'; 
  END IF;

  INSERT INTO public.profiles (id, roll_number, full_name, email, seeme_qr_id)
  VALUES (
    NEW.id,
    meta_roll_number,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    new_qr_id
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ─── Update updated_at Trigger ───────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_user_links_updated_at BEFORE UPDATE ON user_links
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_app_config_updated_at BEFORE UPDATE ON app_config
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_feature_flags_updated_at BEFORE UPDATE ON feature_flags
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_user_devices_updated_at BEFORE UPDATE ON user_devices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── Search Vector Update Trigger ────────────────────────────

CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', COALESCE(NEW.full_name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.roll_number, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.department, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.bio, '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(array_to_string(NEW.skills, ' '), '')), 'B');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_search_vector
  BEFORE INSERT OR UPDATE OF full_name, roll_number, department, bio, skills ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_search_vector();

-- ─── Rate Limiting ───────────────────────────────────────────

CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id UUID,
  p_action TEXT,
  p_max_count INTEGER,
  p_window INTERVAL DEFAULT '1 hour'
)
RETURNS BOOLEAN AS $$
DECLARE
  event_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO event_count
  FROM rate_limit_events
  WHERE user_id = p_user_id
    AND action_type = p_action
    AND created_at > (now() - p_window);

  RETURN event_count < p_max_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION record_rate_limit_event(
  p_user_id UUID,
  p_action TEXT
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO rate_limit_events (user_id, action_type) VALUES (p_user_id, p_action);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── Account Deletion Functions ──────────────────────────────

CREATE OR REPLACE FUNCTION soft_delete_account(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE profiles SET
    account_status = 'soft_deleted',
    deleted_at = now(),
    deletion_scheduled_at = now() + interval '30 days',
    visibility = 'hidden'
  WHERE id = p_user_id AND account_status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION recover_account(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE profiles SET
    account_status = 'active',
    deleted_at = NULL,
    deletion_scheduled_at = NULL,
    visibility = 'public'
  WHERE id = p_user_id AND account_status = 'soft_deleted';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION purge_expired_accounts()
RETURNS INTEGER AS $$
DECLARE
  purged_count INTEGER := 0;
  expired_user RECORD;
BEGIN
  FOR expired_user IN
    SELECT id FROM profiles
    WHERE account_status = 'soft_deleted'
      AND deletion_scheduled_at < now()
  LOOP
    -- Delete storage files (handled by CASCADE + storage policies)
    -- Delete the profile (cascades to all related tables)
    DELETE FROM profiles WHERE id = expired_user.id;
    purged_count := purged_count + 1;
  END LOOP;

  RETURN purged_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── Profile View with Rate Limiting ─────────────────────────

CREATE OR REPLACE FUNCTION increment_profile_views(
  p_viewer UUID,
  p_viewed UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  allowed BOOLEAN;
BEGIN
  -- Don't track self-views
  IF p_viewer = p_viewed THEN RETURN false; END IF;

  -- Check rate limit (300/hour default)
  SELECT check_rate_limit(p_viewer, 'profile_view', 300) INTO allowed;
  IF NOT allowed THEN RETURN false; END IF;

  -- Record the view
  INSERT INTO profile_views (viewer_id, viewed_id) VALUES (p_viewer, p_viewed);

  -- Record rate limit event
  PERFORM record_rate_limit_event(p_viewer, 'profile_view');

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── Data Retention Cleanup ──────────────────────────────────

CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS TABLE(table_name TEXT, deleted_count BIGINT) AS $$
BEGIN
  -- Scan history (180 days)
  DELETE FROM scan_history WHERE expires_at < now();
  RETURN QUERY SELECT 'scan_history'::TEXT, COUNT(*) FROM scan_history WHERE false;

  -- Profile views (180 days)
  DELETE FROM profile_views WHERE expires_at < now();

  -- Activity logs (365 days)
  DELETE FROM activity_logs WHERE expires_at < now();

  -- Audit logs (365 days)
  DELETE FROM audit_logs WHERE expires_at < now();

  -- Rate limit events (24 hours)
  DELETE FROM rate_limit_events WHERE created_at < (now() - interval '24 hours');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
