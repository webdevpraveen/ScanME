-- ============================================================
-- SeeMe Database Migration 007 — Storage Buckets & Policies
-- ============================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('id-cards', 'id-cards', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('documents', 'documents', false, 10485760, NULL);

-- ─── Avatars Bucket Policies ─────────────────────────────────

-- Anyone can view public avatars
CREATE POLICY "avatars_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

-- Users can upload to their own folder
CREATE POLICY "avatars_upload_own" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update their own avatars
CREATE POLICY "avatars_update_own" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own avatars
CREATE POLICY "avatars_delete_own" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ─── ID Cards Bucket Policies ────────────────────────────────

-- Users can upload to their own folder
CREATE POLICY "id_cards_upload_own" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'id-cards'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Only moderators and admins can view ID cards
CREATE POLICY "id_cards_moderator_admin_read" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'id-cards'
    AND is_admin_or_moderator(auth.uid())
  );

-- Users can view their own ID cards
CREATE POLICY "id_cards_view_own" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'id-cards'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ─── Documents Bucket Policies ───────────────────────────────

-- Admin only access
CREATE POLICY "documents_admin_only" ON storage.objects
  FOR ALL USING (
    bucket_id = 'documents'
    AND is_admin(auth.uid())
  );
