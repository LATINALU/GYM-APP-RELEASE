-- Create current_user_id() function for InsForge
-- This converts the current_user (email) to UUID from users table
CREATE OR REPLACE FUNCTION current_user_id() RETURNS UUID AS $$
SELECT id FROM users WHERE email = current_user;
$$ LANGUAGE sql SECURITY DEFINER;
