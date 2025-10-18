-- SafeGuard - Danger Alert Row Level Security Policies
-- These policies ensure data security and proper access control

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Users table policies
-- Allow users to insert their own profile during signup
CREATE POLICY users_insert_policy ON users
  FOR INSERT
  WITH CHECK (true);

-- Allow users to update their own profile
CREATE POLICY users_update_policy ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (true);

-- Allow users to view their own profile
CREATE POLICY users_select_policy ON users
  FOR SELECT
  USING (auth.uid() = id);

-- Emergency alerts policies
-- Allow authenticated users to perform all operations
CREATE POLICY emergency_alerts_all_policy ON emergency_alerts
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- Public incidents policies
-- Allow authenticated users to perform all operations
CREATE POLICY public_incidents_all_policy ON public_incidents
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- Chat messages policies
-- Allow authenticated users to perform all operations
CREATE POLICY chat_messages_all_policy ON chat_messages
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);
