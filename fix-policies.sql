-- Fix policies for GYM-APP schema
-- First create the function, then recreate policies

-- Create current_user_id() function
CREATE OR REPLACE FUNCTION current_user_id() RETURNS UUID AS $$
SELECT id FROM users WHERE email = current_user;
$$ LANGUAGE sql SECURITY DEFINER;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS admin_all_gyms ON gyms;
DROP POLICY IF EXISTS owner_own_gym ON gyms;
DROP POLICY IF EXISTS exercises_visibility ON exercises;

-- Recreate policies
CREATE POLICY admin_all_gyms ON gyms FOR ALL TO authenticated
    USING (
        EXISTS (SELECT 1 FROM users WHERE users.id = current_user_id()::uuid AND users.role = 'admin')
    );

CREATE POLICY owner_own_gym ON gyms FOR ALL TO authenticated
    USING (
        id IN (SELECT gym_id FROM users WHERE users.id = current_user_id()::uuid AND users.role = 'owner')
        OR EXISTS (SELECT 1 FROM users WHERE users.id = current_user_id()::uuid AND users.role = 'admin')
    );

CREATE POLICY exercises_visibility ON exercises FOR SELECT TO authenticated
    USING (
        scope = 'global'
        OR gym_id IN (SELECT gym_id FROM users WHERE users.id = current_user_id()::uuid)
        OR EXISTS (SELECT 1 FROM users WHERE users.id = current_user_id()::uuid AND users.role = 'admin')
    );
