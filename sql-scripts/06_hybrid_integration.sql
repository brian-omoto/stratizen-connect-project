-- Hybrid Database Integration Demonstrations
-- Stored procedures that work with both MySQL and MongoDB concepts

USE stratizen_connect;

DELIMITER //

-- Procedure: Get User Activity Summary (MySQL + MongoDB concept)
CREATE PROCEDURE GetUserHybridActivity(IN user_id_param INT)
BEGIN
    -- MySQL Data (Structured)
    SELECT 
        u.user_id,
        u.username,
        u.first_name,
        u.role,
        COUNT(DISTINCT p.post_id) as mysql_posts,
        COUNT(DISTINCT er.registration_id) as mysql_event_registrations,
        COUNT(DISTINCT pe.engagement_id) as mysql_engagements,
        COUNT(DISTINCT gm.group_id) as mysql_groups_joined,
        
        -- MongoDB-linked data (conceptual - these would come from application layer)
        '(See MongoDB for detailed activities)' as mongodb_activities,
        '(See MongoDB for chat history)' as mongodb_chats,
        '(See MongoDB for notifications)' as mongodb_notifications,
        
        -- Combined metrics
        (COUNT(DISTINCT p.post_id) + 
         COUNT(DISTINCT er.registration_id) + 
         COUNT(DISTINCT pe.engagement_id)) as total_mysql_activity_score
         
    FROM users u
    LEFT JOIN posts p ON u.user_id = p.user_id
    LEFT JOIN event_registrations er ON u.user_id = er.user_id
    LEFT JOIN post_engagements pe ON u.user_id = pe.user_id
    LEFT JOIN group_members gm ON u.user_id = gm.user_id
    WHERE u.user_id = user_id_param
    GROUP BY u.user_id, u.username, u.first_name, u.role;
    
    -- Additional: Show events this user might be interested in (based on groups)
    SELECT 
        e.event_id,
        e.event_name,
        e.event_date,
        e.venue,
        ug.group_name,
        '(Real-time availability from MongoDB)' as real_time_rsvp_status
    FROM events e
    JOIN user_groups ug ON e.group_id = ug.group_id
    JOIN group_members gm ON ug.group_id = gm.group_id
    WHERE gm.user_id = user_id_param
    AND e.event_date >= NOW()
    ORDER BY e.event_date;
    
END//

-- Procedure: Cross-Database System Health Check
CREATE PROCEDURE CheckHybridSystemHealth()
BEGIN
    -- MySQL Health Check
    SELECT 
        'MySQL' as database_type,
        COUNT(*) as user_count,
        (SELECT COUNT(*) FROM posts) as post_count,
        (SELECT COUNT(*) FROM events) as event_count,
        'Structured data storage' as purpose,
        'ACID transactions, Complex queries' as strengths
    FROM users
    
    UNION ALL
    
    -- MongoDB Health Check (Conceptual)
    SELECT 
        'MongoDB' as database_type,
        '(See MongoDB for user activities)' as user_count,
        '(See MongoDB for real-time chats)' as post_count,
        '(See MongoDB for notifications)' as event_count,
        'Unstructured real-time data' as purpose,
        'Flexible schema, High write throughput' as strengths;
        
    -- Data Flow Summary
    SELECT 
        'Data Flow: MySQL → MongoDB' as flow_direction,
        'User registrations, Posts, Events' as data_types,
        'Structured storage with relationships' as description
    
    UNION ALL
    
    SELECT 
        'Data Flow: MongoDB → MySQL' as flow_direction,
        'Activity logs, Analytics, Notifications' as data_types,
        'Real-time processing and flexible data' as description;
        
END//

-- Procedure: Hybrid Search Across Platforms
CREATE PROCEDURE HybridSearch(IN search_term VARCHAR(255))
BEGIN
    -- MySQL Search (Structured content)
    SELECT 
        'MySQL Posts' as source,
        p.post_id,
        SUBSTRING(p.content, 1, 100) as content_preview,
        u.username,
        p.created_at
    FROM posts p
    JOIN users u ON p.user_id = u.user_id
    WHERE p.content LIKE CONCAT('%', search_term, '%')
    
    UNION ALL
    
    SELECT 
        'MySQL Events' as source,
        e.event_id,
        e.event_name as content_preview,
        u.username,
        e.created_at
    FROM events e
    JOIN users u ON e.organizer_id = u.user_id
    WHERE e.event_name LIKE CONCAT('%', search_term, '%')
    OR e.description LIKE CONCAT('%', search_term, '%')
    
    ORDER BY created_at DESC
    LIMIT 10;
    
    -- Note: MongoDB search would happen in application layer for:
    -- - Chat messages
    -- - User activities  
    -- - Notifications
    -- This demonstrates the complementary nature of both databases
    
END//

DELIMITER ;