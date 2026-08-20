-- ============================================================
-- SeeMe Database Migration 002 — Core Tables
-- ============================================================

-- ─── Profiles ────────────────────────────────────────────────
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  roll_number TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  department TEXT,
  academic_year TEXT,
  bio TEXT,
  skills TEXT[] DEFAULT '{}',
  interests TEXT[] DEFAULT '{}',
  avatar_url TEXT,
  is_verified BOOLEAN NOT NULL DEFAULT false,
  role user_role NOT NULL DEFAULT 'student',
  visibility visibility_level NOT NULL DEFAULT 'public',
  profile_completion INTEGER NOT NULL DEFAULT 0,
  seeme_qr_id TEXT UNIQUE NOT NULL,
  account_status account_status NOT NULL DEFAULT 'active',
  deleted_at TIMESTAMPTZ,
  deletion_scheduled_at TIMESTAMPTZ,
  search_vector TSVECTOR,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Constraints
  CONSTRAINT roll_number_format CHECK (roll_number ~ '^[0-9]{15}$'),
  CONSTRAINT bio_max_length CHECK (char_length(bio) <= 500),
  CONSTRAINT skills_max_count CHECK (array_length(skills, 1) IS NULL OR array_length(skills, 1) <= 20),
  CONSTRAINT interests_max_count CHECK (array_length(interests, 1) IS NULL OR array_length(interests, 1) <= 20)
);

COMMENT ON TABLE profiles IS 'Core user profiles — one per auth.users entry';
COMMENT ON COLUMN profiles.seeme_qr_id IS 'Internal SeeMe QR identifier (UUID format)';
COMMENT ON COLUMN profiles.search_vector IS 'Full-text search index for user discovery';

-- ─── User Links (Social/Contact) ────────────────────────────
CREATE TABLE user_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  platform link_platform NOT NULL,
  url TEXT NOT NULL,
  display_name TEXT,
  is_visible BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE user_links IS 'Social media and contact links for each student';

-- ─── Student Verifications ───────────────────────────────────
CREATE TABLE student_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  id_card_front_url TEXT,
  roll_number_declared TEXT,
  status verification_status NOT NULL DEFAULT 'pending',
  reviewed_by UUID REFERENCES profiles(id),
  review_notes TEXT,
  attempt_number INTEGER NOT NULL DEFAULT 1,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE student_verifications IS 'Verification requests with moderator review workflow';
COMMENT ON COLUMN student_verifications.attempt_number IS 'Tracks re-submissions after rejection';

-- ─── Scan History ────────────────────────────────────────────
CREATE TABLE scan_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scanner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  scanned_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  scan_type TEXT DEFAULT 'qr',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '180 days')
);

COMMENT ON TABLE scan_history IS 'Records of QR scans with 180-day retention';

-- ─── Notifications ───────────────────────────────────────────
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Profile Views ───────────────────────────────────────────
CREATE TABLE profile_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  viewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  viewed_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '180 days')
);

-- ─── Reported Profiles ──────────────────────────────────────
CREATE TABLE reported_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reported_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  status report_status NOT NULL DEFAULT 'pending',
  reviewed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

-- ─── Blocked Users ───────────────────────────────────────────
CREATE TABLE blocked_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id),
  CONSTRAINT no_self_block CHECK (blocker_id != blocked_id)
);

-- ─── User Devices (FCM tokens) ──────────────────────────────
CREATE TABLE user_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  device_token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  device_info JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE reported_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
