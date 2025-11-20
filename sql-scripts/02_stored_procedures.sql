USE stratizen_connect;

-- Stored Procedure 1: WITH PARAMETERS - Get user posts and activities
DELIMITER //
CREATE PROCEDURE GetUserDashboard(IN user_id_param INT)
BEGIN
    -- Get user basic info
    SELECT user_id, username, first_name, last_name, role, major 
    FROM users 
    WHERE user_id = user_id_param;
    
    -- Get user's recent posts
    SELECT p.post_id, p.content, p.post_type, p.created_at, ug.group_name
    FROM posts p
    LEFT JOIN user_groups ug ON p.group_id = ug.group_id
    WHERE p.user_id = user_id_param
    ORDER BY p.created_at DESC
    LIMIT 10;
    
    -- Get user's group memberships
    SELECT ug.group_id, ug.group_name, ug.group_type, gm.role as member_role
    FROM group_members gm
    JOIN user_groups ug ON gm.group_id = ug.group_id
    WHERE gm.user_id = user_id_param;
    
    -- Get upcoming events for user's groups
    SELECT e.event_id, e.event_name, e.event_date, e.venue, ug.group_name
    FROM events e
    JOIN user_groups ug ON e.group_id = ug.group_id
    JOIN group_members gm ON ug.group_id = gm.group_id
    WHERE gm.user_id = user_id_param
    AND e.event_date >= NOW()
    ORDER BY e.event_date ASC
    LIMIT 5;
END//
DELIMITER ;

-- Stored Procedure 2: WITHOUT PARAMETERS - Get system statistics
DELIMITER //
CREATE PROCEDURE GetSystemStatistics()
BEGIN
    -- User statistics
    SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN role = 'student' THEN 1 END) as student_count,
        COUNT(CASE WHEN role = 'lecturer' THEN 1 END) as lecturer_count,
        COUNT(CASE WHEN role = 'staff' THEN 1 END) as staff_count
    FROM users;
    
    -- Group statistics
    SELECT 
        COUNT(*) as total_groups,
        COUNT(CASE WHEN group_type = 'course' THEN 1 END) as course_groups,
        COUNT(CASE WHEN group_type = 'club' THEN 1 END) as club_groups,
        COUNT(CASE WHEN group_type = 'department' THEN 1 END) as department_groups
    FROM user_groups;
    
    -- Activity statistics
    SELECT 
        COUNT(*) as total_posts,
        COUNT(CASE WHEN post_type = 'announcement' THEN 1 END) as announcements,
        COUNT(CASE WHEN post_type = 'resource' THEN 1 END) as resources,
        COUNT(DISTINCT user_id) as active_posters
    FROM posts
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);
    
    -- Marketplace statistics
    SELECT 
        COUNT(*) as total_listings,
        COUNT(CASE WHEN status = 'available' THEN 1 END) as available_listings,
        COUNT(CASE WHEN status = 'sold' THEN 1 END) as sold_listings,
        COUNT(DISTINCT seller_id) as active_sellers
    FROM marketplace_listings;
END//
DELIMITER ;

-- Stored Procedure 3: WITH PARAMETERS - Search posts and content
DELIMITER //
CREATE PROCEDURE SearchContent(IN search_term VARCHAR(255), IN group_id_param INT)
BEGIN
    IF group_id_param IS NULL THEN
        -- Search across all groups
        SELECT p.post_id, p.content, p.post_type, p.created_at, 
               u.username, u.first_name, ug.group_name
        FROM posts p
        JOIN users u ON p.user_id = u.user_id
        LEFT JOIN user_groups ug ON p.group_id = ug.group_id
        WHERE p.content LIKE CONCAT('%', search_term, '%')
        ORDER BY p.created_at DESC
        LIMIT 20;
    ELSE
        -- Search within specific group
        SELECT p.post_id, p.content, p.post_type, p.created_at, 
               u.username, u.first_name, ug.group_name
        FROM posts p
        JOIN users u ON p.user_id = u.user_id
        JOIN user_groups ug ON p.group_id = ug.group_id
        WHERE p.content LIKE CONCAT('%', search_term, '%')
        AND p.group_id = group_id_param
        ORDER BY p.created_at DESC
        LIMIT 20;
    END IF;
END//
DELIMITER ;