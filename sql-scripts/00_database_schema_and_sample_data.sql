-- Create Database
CREATE DATABASE stratizen_connect;
USE stratizen_connect;

-- Users Table
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role ENUM('student', 'lecturer', 'staff', 'admin') NOT NULL,
    major VARCHAR(100),
    year_of_study INT,
    profile_picture_url VARCHAR(255),
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Departments Table
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL,
    description TEXT
);

-- Courses Table
CREATE TABLE courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    course_code VARCHAR(20) UNIQUE NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    department_id INT,
    credits INT,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Clubs Table
CREATE TABLE clubs (
    club_id INT PRIMARY KEY AUTO_INCREMENT,
    club_name VARCHAR(100) NOT NULL,
    description TEXT,
    advisor_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (advisor_id) REFERENCES users(user_id)
);

USE stratizen_connect;

-- USER_GROUPS Table (Connects courses, clubs, and departments)
CREATE TABLE user_groups (
    group_id INT PRIMARY KEY AUTO_INCREMENT,
    group_name VARCHAR(100) NOT NULL,
    group_type ENUM('course', 'club', 'department', 'study') NOT NULL,
    description TEXT,
    course_id INT NULL,
    club_id INT NULL,
    department_id INT NULL,
    created_by INT NOT NULL,
    is_private BOOLEAN DEFAULT FALSE,
    max_members INT DEFAULT 100,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (club_id) REFERENCES clubs(club_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id)
);

-- Group Members Table
CREATE TABLE group_members (
    group_member_id INT PRIMARY KEY AUTO_INCREMENT,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('member', 'admin', 'moderator') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES user_groups(group_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_membership (group_id, user_id)
);

-- Posts Table
CREATE TABLE posts (
    post_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    group_id INT NULL,
    content TEXT NOT NULL,
    post_type ENUM('feed_post', 'announcement', 'resource', 'marketplace') DEFAULT 'feed_post',
    upvote_count INT DEFAULT 0,
    resource_url VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (group_id) REFERENCES user_groups(group_id)
);

-- Events Table
CREATE TABLE events (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    event_name VARCHAR(200) NOT NULL,
    description TEXT,
    organizer_id INT NOT NULL,
    group_id INT NULL,
    event_date DATETIME NOT NULL,
    venue VARCHAR(100),
    max_attendees INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organizer_id) REFERENCES users(user_id),
    FOREIGN KEY (group_id) REFERENCES user_groups(group_id)
);

-- Messages Table
CREATE TABLE messages (
    message_id INT PRIMARY KEY AUTO_INCREMENT,
    sender_id INT NOT NULL,
    receiver_id INT NULL,
    group_id INT NULL,
    message_text TEXT NOT NULL,
    message_type ENUM('direct', 'group') NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (receiver_id) REFERENCES users(user_id),
    FOREIGN KEY (group_id) REFERENCES user_groups(group_id),
    CHECK ((receiver_id IS NOT NULL AND group_id IS NULL) OR (receiver_id IS NULL AND group_id IS NOT NULL))
);

-- Marketplace Listings Table (FIXED - removed 'condition' keyword)
CREATE TABLE marketplace_listings (
    listing_id INT PRIMARY KEY AUTO_INCREMENT,
    seller_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    category ENUM('textbook', 'electronics', 'furniture', 'housing', 'other') NOT NULL,
    item_condition ENUM('new', 'like_new', 'good', 'fair') DEFAULT 'good',  -- Changed from 'condition'
    status ENUM('available', 'sold', 'pending') DEFAULT 'available',
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES users(user_id)
);

-- Create event_registrations table to track who registered for events
CREATE TABLE event_registrations (
    registration_id INT PRIMARY KEY AUTO_INCREMENT,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    attendance_status ENUM('registered', 'attended', 'cancelled') DEFAULT 'registered',
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_event_registration (event_id, user_id)
);

-- Create post_engagements table to track likes, views, etc. (COMPLETE VERSION)
CREATE TABLE post_engagements (
    engagement_id INT PRIMARY KEY AUTO_INCREMENT,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    engagement_type ENUM('like', 'view', 'share', 'save') NOT NULL,
    engaged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_post_engagement (post_id, user_id, engagement_type)
);

-- Insert Strathmore users
INSERT INTO users (username, email, password_hash, first_name, last_name, role, major, year_of_study, bio) VALUES
('j.ochele', 'dollan.ochele@strathmore.edu', 'hashed_pass_1', 'Dollan', 'Ochele', 'student', 'Bachelor of Business Information Technology', 2, 'BBIT Year 2 student interested in database systems and web development'),
('r.mohamed', 'rafa.mohamed@strathmore.edu', 'hashed_pass_2', 'Rafa', 'Mohamed', 'student', 'Bachelor of Commerce', 3, 'BCOM Finance major, involved in student leadership'),
('a.kwikiriza', 'abraham.kwikiriza@strathmore.edu', 'hashed_pass_3', 'Abraham', 'Kwikiriza', 'student', 'Bachelor of Business Science', 2, 'Actuarial Science student, math enthusiast'),
('c.matu', 'chantal.matu@strathmore.edu', 'hashed_pass_4', 'Chantal', 'Matu', 'student', 'Bachelor of Laws', 3, 'Law student, debate club president'),
('j.mapelu', 'joe.mapelu@strathmore.edu', 'hashed_pass_5', 'Joe', 'Mapelu', 'student', 'Bachelor of Business Information Technology', 2, 'BBIT student passionate about cybersecurity'),
('b.omoto', 'brian.omoto@strathmore.edu', 'hashed_pass_6', 'Brian', 'Omoto', 'student', 'Bachelor of Commerce', 1, 'First year BCOM student, adapting to university life'),
('dr.kamau', 'john.kamau@strathmore.edu', 'hashed_pass_7', 'Dr. John', 'Kamau', 'lecturer', 'Information Technology', NULL, 'Senior Lecturer in IT, Database Systems specialist'),
('prof.nyongesa', 'mary.nyongesa@strathmore.edu', 'hashed_pass_8', 'Prof. Mary', 'Nyongesa', 'lecturer', 'Commerce', NULL, 'Professor of Finance and Investment'),
('adv.muthoni', 'grace.muthoni@strathmore.edu', 'hashed_pass_9', 'Adv. Grace', 'Muthoni', 'lecturer', 'Law', NULL, 'Law School faculty, corporate law expert'),
('admin.ogutu', 'peter.ogutu@strathmore.edu', 'hashed_pass_10', 'Peter', 'Ogutu', 'admin', NULL, NULL, 'Registrar Office - Student Affairs'),
('s.aketch', 'sarah.aketch@strathmore.edu', 'hashed_pass_11', 'Sarah', 'Aketch', 'staff', NULL, NULL, 'IT Department - Systems Administrator'),
('cafeteria.mgr', 'david.kip@strathmore.edu', 'hashed_pass_12', 'David', 'Kiprop', 'staff', NULL, NULL, 'Cafeteria Management - Food Services');

-- Insert Strathmore departments
INSERT INTO departments (department_name, description) VALUES
('School of Management and Commerce', 'Offers BCOM, BBS, and other business programs'),
('School of Computing and Engineering', 'BBIT, Computer Science, and Engineering programs'),
('Strathmore Law School', 'Bachelor of Laws and legal studies'),
('School of Humanities and Social Sciences', 'Communication, Development, and International Studies'),
('Strathmore Business School', 'Graduate business programs and executive education'),
('Institute of Mathematical Sciences', 'Mathematics, Actuarial Science, and Statistics'),
('Student Affairs Department', 'Student welfare, activities, and support services'),
('IT Services Department', 'Campus technology infrastructure and support'),
('Library Department', 'University library and research resources'),
('Cafeteria Department', 'Food services and campus dining'),
('Sports Department', 'Athletics, fitness, and recreational activities'),
('Career Services Office', 'Internships, job placements, and career guidance');

-- Insert Strathmore courses
INSERT INTO courses (course_code, course_name, department_id, credits) VALUES
('BBIT 2201', 'Advanced Database Systems', 2, 4),
('BBIT 2103', 'Object Oriented Programming', 2, 3),
('BCOM 3204', 'Financial Management', 1, 3),
('BBS 2301', 'Actuarial Mathematics', 6, 4),
('LLB 3102', 'Contract Law', 3, 3),
('BBIT 3107', 'Web Technologies', 2, 3),
('BCOM 2101', 'Business Statistics', 1, 3),
('BBIT 3205', 'Network Security', 2, 4),
('BBS 2203', 'Investment Analysis', 1, 3),
('LLB 4105', 'International Business Law', 3, 3),
('BBIT 4102', 'Software Engineering', 2, 4),
('BCOM 4108', 'Strategic Management', 1, 3);

-- Insert Strathmore clubs
INSERT INTO clubs (club_name, description, advisor_id) VALUES
('Strathmore Computing Society', 'Technology and programming enthusiasts club', 7),
('Finance and Investment Club', 'Stock market, investments and financial literacy', 8),
('Strathmore Law Society', 'Legal debates, moots and career development', 9),
('Strathmore Entrepreneurs Society', 'Startup culture and business innovation', 8),
('Strathmore Debate Club', 'Public speaking and competitive debating', 9),
('Strathmore Christian Union', 'Fellowship and spiritual growth activities', 10),
('Strathmore Sports Club', 'Football, basketball, rugby and athletics', 11),
('Strathmore Music Society', 'Choir, band and musical performances', 4),
('Strathmore Community Service Club', 'Volunteering and social impact projects', 10),
('Strathmore International Students Association', 'Support for international students', 10),
('Strathmore Accounting Students Association', 'Professional accounting development', 8),
('Strathmore Environmental Club', 'Sustainability and environmental awareness', 10);

-- Insert user groups
INSERT INTO user_groups (group_name, group_type, course_id, club_id, department_id, created_by, description, is_private) VALUES
('BBIT 2201 - Advanced DB 2024', 'course', 1, NULL, NULL, 7, 'Official group for Advanced Database Systems Aug 2024 intake', FALSE),
('BCOM 3204 Financial Mgmt Class', 'course', 3, NULL, NULL, 8, 'Financial Management discussions and announcements', FALSE),
('Strathmore Computing Society Members', 'club', NULL, 1, NULL, 1, 'Active members of Strathmore Computing Society', FALSE),
('Finance Club Executives 2024', 'club', NULL, 2, NULL, 2, 'Executive committee for Finance and Investment Club', TRUE),
('Law School Announcements', 'department', NULL, NULL, 3, 9, 'Official announcements from Strathmore Law School', FALSE),
('BBIT Year 2 Study Group', 'study', NULL, NULL, NULL, 1, 'Collaborative study sessions for BBIT second years', FALSE),
('IT Services Notifications', 'department', NULL, NULL, 8, 11, 'System maintenance and IT service updates', FALSE),
('Cafeteria Specials', 'department', NULL, NULL, 10, 12, 'Daily specials and menu updates from cafeteria', FALSE),
('Career Services Opportunities', 'department', NULL, NULL, 12, 10, 'Internship and job opportunity announcements', FALSE),
('International Students Support', 'club', NULL, 10, NULL, 10, 'Support and social group for international students', FALSE),
('BBIT Web Tech Project Group', 'study', 6, NULL, NULL, 5, 'Group project collaboration for Web Technologies', TRUE),
('Graduation Committee 2024', 'study', NULL, NULL, NULL, 10, 'Planning committee for 2024 graduation ceremony', TRUE);

-- Insert group memberships
INSERT INTO group_members (group_id, user_id, role) VALUES
-- BBIT Database Class (Group 1)
(1, 1, 'admin'), (1, 5, 'member'), (1, 7, 'admin'), (1, 2, 'member'), (1, 3, 'member'),
-- Finance Class (Group 2)
(2, 2, 'admin'), (2, 6, 'member'), (2, 8, 'admin'), (2, 3, 'member'),
-- Computing Society (Group 3)
(3, 1, 'admin'), (3, 5, 'moderator'), (3, 7, 'member'), (3, 11, 'member'), (3, 2, 'member'),
-- Finance Club Executives (Group 4)
(4, 2, 'admin'), (4, 8, 'member'), (4, 3, 'member'),
-- Law School Announcements (Group 5)
(5, 4, 'member'), (5, 9, 'admin'), (5, 10, 'member'),
-- BBIT Study Group (Group 6)
(6, 1, 'admin'), (6, 5, 'member'), (6, 2, 'member'),
-- IT Services (Group 7)
(7, 11, 'admin'), (7, 1, 'member'), (7, 5, 'member'), (7, 10, 'member'),
-- Cafeteria (Group 8)
(8, 12, 'admin'), (8, 1, 'member'), (8, 2, 'member'), (8, 3, 'member'), (8, 4, 'member'),
-- Career Services (Group 9)
(9, 10, 'admin'), (9, 1, 'member'), (9, 2, 'member'), (9, 3, 'member'), (9, 4, 'member'),
-- International Students (Group 10)
(10, 10, 'admin'), (10, 3, 'member');

-- Insert posts
INSERT INTO posts (user_id, group_id, content, post_type, upvote_count, resource_url) VALUES
-- Course announcements and discussions
(7, 1, 'Welcome to BBIT 2201 Advanced Database Systems! First lecture will cover database normalization and SQL optimization. Required textbook: Database Systems by Connolly & Begg', 'announcement', 15, NULL),
(1, 1, 'Can someone explain the difference between 2NF and 3NF normalization? Working on the assignment and got stuck on question 3.', 'feed_post', 8, NULL),
(8, 2, 'Financial Management mid-term exam scheduled for March 15th. Chapters 1-6 will be covered. Study groups can book rooms through student affairs.', 'announcement', 12, '/resources/finance_syllabus.pdf'),
(2, 2, 'Found this great YouTube playlist on corporate finance that explains NPV and IRR really well: https://youtube.com/playlist?list=XYZ123', 'resource', 25, 'https://youtube.com/playlist?list=XYZ123'),

-- Club activities
(1, 3, 'Computing Society Hackathon announced! Theme: "AI for Social Good". Date: Feb 20-21. Register at: strathmore.edu/computing-hackathon', 'announcement', 32, NULL),
(5, 3, 'Weekly coding practice session moved to Thursday 4PM in STC Lab 3. Bring your laptops!', 'feed_post', 18, NULL),
(2, 4, 'Executive meeting this Friday 2PM to plan the upcoming investment seminar with Kestrel Capital.', 'announcement', 5, NULL),

-- Department announcements
(9, 5, 'Law School Moot Court competition registration now open. Prizes include internships at leading law firms. Deadline: Feb 28th.', 'announcement', 21, '/resources/moot_court_guidelines.pdf'),
(11, 7, 'Scheduled maintenance: Student portal will be unavailable this Saturday 10PM-2AM for system upgrades.', 'announcement', 8, NULL),
(12, 8, 'SPECIAL OFFER: This Wednesday - Buy one pizza get one free! Only at Strathmore Cafeteria from 12-2PM.', 'announcement', 45, NULL),
(10, 9, 'KPMG is hiring interns for their technology advisory division. Application deadline: March 1st. Apply through career portal.', 'announcement', 29, '/resources/kpmg_internship.pdf'),
(4, 5, 'Guest lecture by Senior Counsel on "Digital Law and Cybersecurity" next Monday 10AM in Auditorium A.', 'feed_post', 15, NULL);

-- Insert events
INSERT INTO events (event_name, description, organizer_id, group_id, event_date, venue, max_attendees) VALUES
('Advanced Databases Workshop', 'Hands-on workshop covering MongoDB, SQL optimization, and database design patterns', 7, 1, '2024-02-10 14:00:00', 'STC Lab 4', 30),
('Financial Literacy Seminar', 'Personal finance management, investing basics, and career opportunities in finance', 8, 2, '2024-02-15 16:00:00', 'Business Building Room 201', 50),
('Computing Society Hackathon', '24-hour coding competition with industry judges and cash prizes', 1, 3, '2024-02-20 09:00:00', 'STC Building', 100),
('Law School Moot Court Finals', 'Annual moot court competition finals with guest judges from Supreme Court', 9, 5, '2024-02-25 10:00:00', 'Law School Auditorium', 200),
('Career Fair 2024', 'Meet top employers: Deloitte, Safaricom, KPMG, Equity Bank, and more', 10, 9, '2024-03-05 09:00:00', 'Main Campus Grounds', 500),
('International Food Festival', 'Cultural exchange event with food from different countries', 10, 10, '2024-02-18 12:00:00', 'Student Center', 150),
('BBIT Project Presentation Day', 'Final year project demonstrations and industry showcase', 7, 1, '2024-03-12 08:00:00', 'STC Exhibition Hall', 80),
('Entrepreneurship Summit', 'Startup pitches, investor meetings, and innovation talks', 8, 4, '2024-02-22 14:00:00', 'Auditorium A', 120),
('Sports Day 2024', 'Inter-faculty competitions: football, basketball, athletics', 11, 7, '2024-03-08 08:00:00', 'Sports Complex', 300),
('Library Research Skills Workshop', 'Learn advanced research techniques and academic writing', 10, 9, '2024-02-14 11:00:00', 'Library Training Room', 25),
('Cybersecurity Awareness Talk', 'Protecting your digital identity and online safety best practices', 11, 7, '2024-02-28 15:00:00', 'STC Lab 2', 40),
('Graduation Rehearsal', 'Mandatory rehearsal for all graduating students', 10, 12, '2024-03-15 09:00:00', 'Graduation Square', 600);

-- Insert marketplace listings
INSERT INTO marketplace_listings (seller_id, title, description, price, category, item_condition, status, image_url) VALUES
(1, 'Database Systems Textbook - Connolly & Begg', 'Used but in excellent condition. No highlights or writings. Latest edition.', 3500.00, 'textbook', 'like_new', 'available', '/images/db_textbook.jpg'),
(2, 'Financial Calculator - Texas Instruments BA II Plus', 'Professional financial calculator. Perfect for BCOM and BBS students. Includes case.', 4500.00, 'electronics', 'good', 'available', '/images/fin_calculator.jpg'),
(3, 'Actuarial Mathematics Study Guides', 'Complete set of study materials for Actuarial Science courses. Very helpful for exams.', 2000.00, 'textbook', 'good', 'available', NULL),
(4, 'Law Books Collection', 'Various law textbooks including Contract Law, Constitutional Law, and Legal Writing', 6000.00, 'textbook', 'fair', 'available', '/images/law_books.jpg'),
(5, 'Gaming Laptop - Dell G15', 'Powerful gaming laptop, 16GB RAM, 512GB SSD, RTX 3050. Used for 1 year.', 85000.00, 'electronics', 'like_new', 'available', '/images/gaming_laptop.jpg'),
(6, 'BCOM First Year Textbooks Bundle', 'All required textbooks for BCOM Year 1. Selling as complete set.', 5000.00, 'textbook', 'good', 'pending', NULL),
(1, 'Office Chair - Ergonomic', 'Comfortable office chair with lumbar support. Great for long study sessions.', 5500.00, 'furniture', 'like_new', 'available', '/images/office_chair.jpg'),
(2, 'iPhone 12 - 128GB', 'Good condition, screen protector since day one. Includes charger and case.', 45000.00, 'electronics', 'good', 'available', '/images/iphone12.jpg'),
(3, 'Hostel Room Available - Ole Sangale', 'Single room available for male student. Shared bathroom. Quiet environment.', 18000.00, 'housing', 'new', 'available', '/images/hostel_room.jpg'),
(4, 'Legal Robes and Gowns', 'Complete set of legal attire for law students. Barely used.', 4000.00, 'other', 'like_new', 'available', NULL),
(5, 'Web Development Books', 'HTML, CSS, JavaScript, and React books. Perfect for BBIT Web Tech course.', 3000.00, 'textbook', 'good', 'sold', NULL),
(6, 'Football Boots - Nike Mercurial', 'Size 42, used for one season. Good condition with minimal wear.', 2500.00, 'other', 'fair', 'available', '/images/football_boots.jpg');

-- Insert messages
INSERT INTO messages (sender_id, receiver_id, group_id, message_text, message_type, is_read) VALUES
-- Direct messages
(1, 5, NULL, 'Hey Joe, are you going to the database workshop tomorrow?', 'direct', TRUE),
(5, 1, NULL, 'Yes, I''ll be there. Do you want to meet at the STC entrance at 1:45?', 'direct', TRUE),
(2, 3, NULL, 'Abraham, do you have the solutions for the actuarial math assignment?', 'direct', FALSE),
(7, 1, NULL, 'Dollan, great work on the last database assignment! Your normalization was perfect.', 'direct', TRUE),

-- Group messages
(1, NULL, 1, 'Has anyone started the database normalization assignment yet?', 'group', TRUE),
(5, NULL, 1, 'I''m stuck on question 2 about functional dependencies. Anyone understand it?', 'group', TRUE),
(7, NULL, 1, 'Remember class, office hours are tomorrow 2-4PM if you need help with the assignment', 'group', TRUE),
(2, NULL, 2, 'The financial management textbook is available at the library reserve section', 'group', TRUE),
(8, NULL, 2, 'Study group meeting tomorrow 4PM in library study room 3 for finance mid-term prep', 'group', FALSE),
(1, NULL, 3, 'Hackathon registration closes this Friday! Last chance to form teams', 'group', TRUE),
(11, NULL, 7, 'REMINDER: Student portal maintenance tonight 10PM-2AM. Save your work!', 'group', FALSE),
(12, NULL, 8, 'Today''s special: Chicken biryani with yogurt - only 350 shillings!', 'group', TRUE);

INSERT INTO event_registrations (event_id, user_id, attendance_status) VALUES
-- Database Workshop (event_id 1) - 4 unique users
(1, 1, 'registered'),  -- Dollan
(1, 5, 'registered'),  -- Joe
(1, 2, 'registered'),  -- Rafa
(1, 3, 'registered'),  -- Abraham

-- Financial Seminar (event_id 2) - 3 unique users
(2, 2, 'registered'),  -- Rafa
(2, 3, 'registered'),  -- Abraham
(2, 6, 'registered'),  -- Brian

-- Career Fair (event_id 5) - 6 unique users
(5, 1, 'registered'),  -- Dollan
(5, 4, 'registered'),  -- Chantal
(5, 5, 'registered'),  -- Joe
(5, 6, 'registered'),  -- Brian
(5, 7, 'registered'),  -- Dr. Kamau
(5, 8, 'registered'),  -- Prof. Nyongesa

-- Hackathon (event_id 3) - 3 unique users
(3, 1, 'registered'),  -- Dollan
(3, 11, 'registered'), -- Sarah
(3, 12, 'registered'), -- David

-- Sports Day (event_id 9) - 4 unique users
(9, 2, 'registered'),  -- Rafa
(9, 3, 'registered'),  -- Abraham
(9, 4, 'registered'),  -- Chantal
(9, 6, 'registered');  -- Brian

-- post engagements data 
INSERT INTO post_engagements (post_id, user_id, engagement_type) VALUES
-- Engagements with Dr. Kamau's welcome post (post_id 1)
(1, 1, 'view'),
(1, 2, 'view'),
(1, 3, 'view'),
(1, 4, 'view'),
(1, 5, 'view'),
(1, 6, 'view'),
(1, 1, 'like'),
(1, 2, 'like'),
(1, 3, 'like'),
(1, 5, 'like'),

-- Engagements with Dollan's question post (post_id 2)
(2, 5, 'like'),
(2, 7, 'like'),
(2, 2, 'like'),
(2, 3, 'like'),
(2, 1, 'view'),
(2, 4, 'view'),

-- Engagements with Rafa's resource post (post_id 4)
(4, 1, 'like'),
(4, 3, 'like'),
(4, 5, 'like'),
(4, 6, 'like'),
(4, 2, 'view'),
(4, 7, 'view'),

-- Engagements with Computing Society post (post_id 6)
(6, 1, 'like'),
(6, 2, 'like'),
(6, 5, 'like'),
(6, 11, 'like'),
(6, 3, 'view'),
(6, 4, 'view'),

-- Engagements with Cafeteria special (post_id 10)
(10, 1, 'like'),
(10, 2, 'like'),
(10, 3, 'like'),
(10, 4, 'like'),
(10, 5, 'like'),
(10, 6, 'like'),
(10, 7, 'view'),
(10, 8, 'view');