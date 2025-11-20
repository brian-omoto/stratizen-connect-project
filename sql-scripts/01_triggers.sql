USE stratizen_connect;

-- Trigger 1: AFTER INSERT - Log new user registration and create welcome notification
DELIMITER //
CREATE TRIGGER after_user_insert
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    -- Log the activity in an audit table (create it first)
    INSERT INTO user_audit_log (user_id, action_type, action_details, performed_at)
    VALUES (NEW.user_id, 'USER_REGISTERED', CONCAT('New user registered: ', NEW.username), NOW());
    
    -- Create a welcome post in relevant groups based on user role
    IF NEW.role = 'student' THEN
        INSERT INTO posts (user_id, group_id, content, post_type)
        VALUES (NEW.user_id, 9, CONCAT('Welcome ', NEW.first_name, ' to Stratizen Connect! Check out career opportunities and events.'), 'announcement');
    END IF;
END//
DELIMITER ;

-- First, create the audit log table
CREATE TABLE user_audit_log (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    action_details TEXT,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Trigger 2: BEFORE UPDATE - Validate email format and prevent invalid updates
DELIMITER //
CREATE TRIGGER before_user_update
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    -- Validate email format
    IF NEW.email NOT LIKE '%@strathmore.edu%' AND NEW.email NOT LIKE '%@strathmore.university%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid email format. Must be a Strathmore email address.';
    END IF;
    
    -- Prevent role changes from student to admin without proper authorization
    IF OLD.role = 'student' AND NEW.role = 'admin' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot change student role to admin directly.';
    END IF;
    
    -- Log the update
    INSERT INTO user_audit_log (user_id, action_type, action_details)
    VALUES (NEW.user_id, 'USER_UPDATED', CONCAT('User profile updated for: ', NEW.username));
END//
DELIMITER ;

-- Trigger 3: AFTER DELETE - Archive deleted posts and log deletion
DELIMITER //
CREATE TRIGGER after_post_delete
AFTER DELETE ON posts
FOR EACH ROW
BEGIN
    -- Archive the deleted post
    INSERT INTO posts_archive (post_id, user_id, group_id, content, post_type, deleted_at)
    VALUES (OLD.post_id, OLD.user_id, OLD.group_id, OLD.content, OLD.post_type, NOW());
    
    -- Log the deletion activity
    INSERT INTO user_audit_log (user_id, action_type, action_details)
    VALUES (OLD.user_id, 'POST_DELETED', CONCAT('Post deleted from group: ', OLD.group_id));
END//
DELIMITER ;

-- Create the posts archive table
CREATE TABLE posts_archive (
    archive_id INT PRIMARY KEY AUTO_INCREMENT,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    group_id INT NULL,
    content TEXT NOT NULL,
    post_type ENUM('feed_post', 'announcement', 'resource', 'marketplace') NOT NULL,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_by INT NULL
);