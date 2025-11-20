USE stratizen_connect;

-- Report 1: Active Users Report (Last 7 days)
SELECT 
    u.user_id,
    u.username,
    u.first_name,
    u.last_name,
    u.role,
    COUNT(p.post_id) as posts_count,
    COUNT(DISTINCT gm.group_id) as groups_joined,
    MAX(p.created_at) as last_activity
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id AND p.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
LEFT JOIN group_members gm ON u.user_id = gm.user_id
GROUP BY u.user_id, u.username, u.first_name, u.last_name, u.role
HAVING posts_count > 0 OR groups_joined > 0
ORDER BY posts_count DESC, last_activity DESC;

-- Report 2: Course Engagement Report
SELECT 
    c.course_code,
    c.course_name,
    ug.group_id,
    COUNT(DISTINCT gm.user_id) as enrolled_students,
    COUNT(p.post_id) as total_posts,
    COUNT(DISTINCT p.user_id) as active_posters,
    ROUND(COUNT(p.post_id) / NULLIF(COUNT(DISTINCT gm.user_id), 0), 2) as posts_per_student
FROM courses c
JOIN user_groups ug ON c.course_id = ug.course_id
LEFT JOIN group_members gm ON ug.group_id = gm.group_id
LEFT JOIN posts p ON ug.group_id = p.group_id AND p.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
WHERE ug.group_type = 'course'
GROUP BY c.course_code, c.course_name, ug.group_id
ORDER BY posts_per_student DESC;

-- Report 3: Marketplace Activity Report
SELECT 
    u.user_id,
    u.username,
    u.first_name,
    u.last_name,
    COUNT(ml.listing_id) as total_listings,
    COUNT(CASE WHEN ml.status = 'sold' THEN 1 END) as sold_listings,
    COUNT(CASE WHEN ml.status = 'available' THEN 1 END) as available_listings,
    COALESCE(SUM(CASE WHEN ml.status = 'sold' THEN ml.price END), 0) as total_sales
FROM users u
LEFT JOIN marketplace_listings ml ON u.user_id = ml.seller_id
WHERE u.role = 'student'
GROUP BY u.user_id, u.username, u.first_name, u.last_name
HAVING total_listings > 0
ORDER BY total_sales DESC, total_listings DESC;

-- Report 4: Event Participation Report
SELECT 
    e.event_id,
    e.event_name,
    e.event_date,
    COUNT(er.registration_id) as registrations
FROM events e
LEFT JOIN event_registrations er ON e.event_id = er.event_id
GROUP BY e.event_id, e.event_name, e.event_date
ORDER BY registrations DESC;