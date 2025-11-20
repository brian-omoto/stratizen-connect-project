USE stratizen_connect;

-- Create different types of users with specific privileges
CREATE USER 'stratizen_student'@'localhost' IDENTIFIED BY 'student_pass123';
CREATE USER 'stratizen_lecturer'@'localhost' IDENTIFIED BY 'lecturer_pass123';
CREATE USER 'stratizen_admin'@'localhost' IDENTIFIED BY 'admin_pass123';

-- Grant permissions based on roles

-- Student: Can read most data, limited writes
GRANT SELECT ON stratizen_connect.users TO 'stratizen_student'@'localhost';
GRANT SELECT ON stratizen_connect.posts TO 'stratizen_student'@'localhost';
GRANT SELECT ON stratizen_connect.events TO 'stratizen_student'@'localhost';
GRANT SELECT ON stratizen_connect.user_groups TO 'stratizen_student'@'localhost';
GRANT SELECT, INSERT ON stratizen_connect.post_engagements TO 'stratizen_student'@'localhost';
GRANT SELECT, INSERT ON stratizen_connect.event_registrations TO 'stratizen_student'@'localhost';

-- Lecturer: Additional permissions for course management
GRANT SELECT, INSERT, UPDATE ON stratizen_connect.posts TO 'stratizen_lecturer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON stratizen_connect.events TO 'stratizen_lecturer'@'localhost';
GRANT SELECT ON stratizen_connect.group_members TO 'stratizen_lecturer'@'localhost';

-- Admin: Full database access
GRANT ALL PRIVILEGES ON stratizen_connect.* TO 'stratizen_admin'@'localhost';

-- Apply the changes
FLUSH PRIVILEGES;

-- Verify user creation
SELECT user, host FROM mysql.user WHERE user LIKE 'stratizen_%';

-- Show grants for each user
SHOW GRANTS FOR 'stratizen_student'@'localhost';
SHOW GRANTS FOR 'stratizen_lecturer'@'localhost';
SHOW GRANTS FOR 'stratizen_admin'@'localhost';

-- Test student permissions (run this as student user in a new connection)
-- First, disconnect and reconnect as 'stratizen_student'

-- These should WORK for student:
SELECT * FROM posts LIMIT 5;
SELECT * FROM events WHERE event_date >= NOW();
INSERT INTO event_registrations (event_id, user_id) VALUES (1, 1);

-- These should FAIL for student:
UPDATE posts SET content = 'Modified' WHERE post_id = 1;
DELETE FROM events WHERE event_id = 1;
SELECT * FROM user_audit_log;

-- Test admin permissions (run as admin user)
-- These should ALL work for admin:
SELECT * FROM user_audit_log;
UPDATE posts SET content = 'Admin modified' WHERE post_id = 1;
DELETE FROM event_registrations WHERE registration_id = 1;

-- Verify the users exist
SELECT user, host, authentication_string FROM mysql.user WHERE user LIKE 'stratizen_%';

-- Show their privileges
SHOW GRANTS FOR 'stratizen_student'@'localhost';
SHOW GRANTS FOR 'stratizen_lecturer'@'localhost'; 
SHOW GRANTS FOR 'stratizen_admin'@'localhost';

