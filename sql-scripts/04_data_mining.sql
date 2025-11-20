USE stratizen_connect;

-- Data Mining Technique 1: Association Rule Mining (Marketplace Patterns)
-- Find: "Users who buy textbooks also tend to buy what other categories?"
SELECT 
    ml1.category as primary_category,
    ml2.category as associated_category,
    COUNT(DISTINCT ml1.seller_id) as users_count,
    ROUND(COUNT(DISTINCT ml2.listing_id) / COUNT(DISTINCT ml1.seller_id), 2) as association_strength
FROM marketplace_listings ml1
JOIN marketplace_listings ml2 ON ml1.seller_id = ml2.seller_id 
    AND ml1.category != ml2.category
    AND ml1.listing_id != ml2.listing_id
WHERE ml1.category = 'textbook'
GROUP BY ml1.category, ml2.category
HAVING users_count >= 2
ORDER BY association_strength DESC;

-- Data Mining Technique 2: Clustering Analysis (User Segmentation)
-- Group users based on their activity patterns
SELECT 
    u.user_id,
    u.username,
    u.role,
    COUNT(DISTINCT p.post_id) as post_count,
    COUNT(DISTINCT er.registration_id) as event_registrations,
    COUNT(DISTINCT pe.engagement_id) as engagements,
    COUNT(DISTINCT gm.group_id) as groups_joined,
    CASE 
        WHEN COUNT(DISTINCT p.post_id) > 5 AND COUNT(DISTINCT er.registration_id) > 3 THEN 'Highly Active'
        WHEN COUNT(DISTINCT p.post_id) > 2 OR COUNT(DISTINCT er.registration_id) > 1 THEN 'Moderately Active'
        ELSE 'Minimally Active'
    END as user_segment
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id
LEFT JOIN event_registrations er ON u.user_id = er.user_id
LEFT JOIN post_engagements pe ON u.user_id = pe.user_id
LEFT JOIN group_members gm ON u.user_id = gm.user_id
WHERE u.role = 'student'
GROUP BY u.user_id, u.username, u.role
ORDER BY post_count DESC, event_registrations DESC;

-- Data Mining Technique 3: Classification (Predict Event Popularity)
-- Analyze what makes events popular based on historical data
SELECT 
    e.event_id,
    e.event_name,
    e.venue,
    ug.group_name,
    DAYNAME(e.event_date) as day_of_week,
    HOUR(e.event_date) as hour_of_day,
    COUNT(er.registration_id) as actual_registrations,
    CASE 
        WHEN COUNT(er.registration_id) > 10 THEN 'High Popularity'
        WHEN COUNT(er.registration_id) > 5 THEN 'Medium Popularity'
        ELSE 'Low Popularity'
    END as popularity_class
FROM events e
LEFT JOIN user_groups ug ON e.group_id = ug.group_id
LEFT JOIN event_registrations er ON e.event_id = er.event_id
GROUP BY e.event_id, e.event_name, e.venue, ug.group_name, e.event_date
ORDER BY actual_registrations DESC;

-- Data Mining Technique 4: Sequential Pattern Mining (User Behavior Flow)
-- Analyze common sequences of user activities
SELECT 
    u1.username,
    ua1.action_type as first_activity,  -- CHANGED: activity_type → action_type
    ua2.action_type as second_activity, -- CHANGED: activity_type → action_type
    COUNT(*) as sequence_count
FROM user_audit_log ua1
JOIN user_audit_log ua2 ON ua1.user_id = ua2.user_id 
    AND ua2.performed_at > ua1.performed_at
    AND TIMESTAMPDIFF(MINUTE, ua1.performed_at, ua2.performed_at) <= 60
JOIN users u1 ON ua1.user_id = u1.user_id
WHERE ua1.action_type != ua2.action_type  -- CHANGED: activity_type → action_type
GROUP BY u1.username, ua1.action_type, ua2.action_type  -- CHANGED: activity_type → action_type
HAVING sequence_count >= 2
ORDER BY sequence_count DESC;