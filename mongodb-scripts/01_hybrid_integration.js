// MongoDB + MySQL Hybrid Integration Demo
// This script demonstrates how both databases work together

const { MongoClient } = require('mongodb');
const mysql = require('mysql2/promise');

class HybridDatabaseManager {
    constructor() {
        this.mongoUri = "mongodb://localhost:27017";
        this.mongoDbName = "stratizen_connect";
        this.mysqlConfig = {
            host: 'localhost',
            user: 'root', // Use your MySQL credentials
            password: '', // Use your MySQL password
            database: 'stratizen_connect'
        };
    }

    async initialize() {
        // Connect to both databases
        this.mongoClient = new MongoClient(this.mongoUri);
        await this.mongoClient.connect();
        this.mongoDb = this.mongoClient.db(this.mongoDbName);
        
        this.mysqlConnection = await mysql.createConnection(this.mysqlConfig);
        
        console.log('✅ Connected to both MySQL and MongoDB');
    }

    // DEMO 1: User Registration Flow (Both Databases)
    async demoUserRegistration() {
        console.log('\n🎯 DEMO 1: User Registration Flow');
        console.log('====================================');

        try {
            // Step 1: MySQL - Create structured user record
            const [mysqlResult] = await this.mysqlConnection.execute(
                `INSERT INTO users (username, email, password_hash, first_name, last_name, role, major, year_of_study) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                ['demo.user', 'demo.user@strathmore.edu', 'hashed_password_123', 'Demo', 'User', 'student', 'Computer Science', 2]
            );
            
            const newUserId = mysqlResult.insertId;
            console.log(`✅ MySQL: User created with ID: ${newUserId}`);

            // Step 2: MongoDB - Log registration activity
            const mongoActivity = await this.mongoDb.collection('user_activities').insertOne({
                user_id: newUserId,
                username: 'demo.user',
                activity_type: 'user_registered',
                activity_details: 'New user registration completed',
                related_mysql_tables: ['users'],
                mysql_user_id: newUserId,
                ip_address: '192.168.1.100',
                user_agent: 'Registration Demo',
                timestamp: new Date()
            });
            console.log(`✅ MongoDB: Activity logged with ID: ${mongoActivity.insertedId}`);

            // Step 3: MongoDB - Create welcome notification
            const notification = await this.mongoDb.collection('notifications').insertOne({
                user_id: newUserId,
                username: 'demo.user',
                notification_type: 'welcome_message',
                title: 'Welcome to Stratizen Connect!',
                message: 'Your account has been created successfully. Start exploring your campus community!',
                is_read: false,
                priority: 'high',
                action_url: '/dashboard',
                mysql_user_id: newUserId,
                created_at: new Date(),
                expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
            });
            console.log(`✅ MongoDB: Welcome notification created`);

            return newUserId;

        } catch (error) {
            console.error('❌ Registration demo failed:', error);
            throw error;
        }
    }

    // DEMO 2: Event Registration with Cross-Database Links
    async demoEventRegistration(userId) {
        console.log('\n🎯 DEMO 2: Event Registration Flow');
        console.log('====================================');

        try {
            // Step 1: MySQL - Register for event
            const [mysqlResult] = await this.mysqlConnection.execute(
                `INSERT INTO event_registrations (event_id, user_id) VALUES (?, ?)`,
                [1, userId] // Event ID 1 = Database Workshop
            );
            
            const registrationId = mysqlResult.insertId;
            console.log(`✅ MySQL: Event registration created with ID: ${registrationId}`);

            // Step 2: MongoDB - Log event registration activity
            await this.mongoDb.collection('user_activities').insertOne({
                user_id: userId,
                username: 'demo.user',
                activity_type: 'event_registered',
                activity_details: 'Registered for Advanced Databases Workshop',
                related_mysql_tables: ['event_registrations', 'events', 'users'],
                mysql_event_id: 1,
                mysql_registration_id: registrationId,
                mysql_user_id: userId,
                timestamp: new Date()
            });

            // Step 3: MongoDB - Create event reminder notification
            await this.mongoDb.collection('notifications').insertOne({
                user_id: userId,
                notification_type: 'event_reminder',
                title: 'Event Registration Confirmed',
                message: 'You are registered for Advanced Databases Workshop tomorrow at 2:00 PM',
                is_read: false,
                priority: 'medium',
                action_url: '/events/1',
                mysql_event_id: 1,
                mysql_registration_id: registrationId,
                created_at: new Date()
            });

            console.log(`✅ Cross-database event registration completed`);

        } catch (error) {
            console.error('❌ Event registration demo failed:', error);
        }
    }

    // DEMO 3: Real-time Chat with MySQL Group Context
    async demoRealTimeChat(userId) {
        console.log('\n🎯 DEMO 3: Real-time Chat with MySQL Context');
        console.log('=============================================');

        try {
            // Step 1: MySQL - Get group information
            const [groups] = await this.mysqlConnection.execute(
                `SELECT ug.group_id, ug.group_name, ug.group_type 
                 FROM user_groups ug 
                 JOIN group_members gm ON ug.group_id = gm.group_id 
                 WHERE gm.user_id = ? LIMIT 1`,
                [userId]
            );

            if (groups.length > 0) {
                const group = groups[0];
                
                // Step 2: MongoDB - Create/Update chat conversation
                const chatUpdate = await this.mongoDb.collection('real_time_chats').updateOne(
                    { 
                        conversation_id: `group_${group.group_id}_demo`,
                        group_id: group.group_id 
                    },
                    {
                        $set: {
                            conversation_id: `group_${group.group_id}_demo`,
                            participants: [userId, 1, 5], // Demo participants
                            participant_names: ['demo.user', 'Dollan Ochele', 'Joe Mapelu'],
                            conversation_type: 'group',
                            group_id: group.group_id,
                            group_name: group.group_name,
                            last_message_at: new Date()
                        },
                        $push: {
                            messages: {
                                message_id: Date.now(),
                                sender_id: userId,
                                sender_name: 'demo.user',
                                message_text: 'Hello everyone! This is a demo message showing MongoDB real-time chat integrated with MySQL groups.',
                                timestamp: new Date(),
                                read_by: [userId]
                            }
                        }
                    },
                    { upsert: true }
                );

                console.log(`✅ MongoDB: Chat created for MySQL group: ${group.group_name}`);
                console.log(`   Group ID: ${group.group_id}, Chat ID: group_${group.group_id}_demo`);
            }

        } catch (error) {
            console.error('❌ Chat demo failed:', error);
        }
    }

    // DEMO 4: Cross-Database Analytics Report
    async demoCrossDatabaseAnalytics() {
        console.log('\n🎯 DEMO 4: Cross-Database Analytics');
        console.log('====================================');

        try {
            // Step 1: Get data from MySQL
            const [mysqlStats] = await this.mysqlConnection.execute(`
                SELECT 
                    COUNT(*) as total_users,
                    COUNT(CASE WHEN role = 'student' THEN 1 END) as student_count,
                    COUNT(CASE WHEN role = 'lecturer' THEN 1 END) as lecturer_count,
                    COUNT(DISTINCT post_id) as total_posts,
                    COUNT(DISTINCT event_id) as total_events
                FROM users 
                LEFT JOIN posts ON users.user_id = posts.user_id
                LEFT JOIN events ON users.user_id = events.organizer_id
            `);

            const mysqlData = mysqlStats[0];
            console.log('📊 MySQL Statistics:');
            console.log(`   - Total Users: ${mysqlData.total_users}`);
            console.log(`   - Students: ${mysqlData.student_count}`);
            console.log(`   - Lecturers: ${mysqlData.lecturer_count}`);
            console.log(`   - Posts: ${mysqlData.total_posts}`);
            console.log(`   - Events: ${mysqlData.total_events}`);

            // Step 2: Get data from MongoDB
            const mongoActivities = await this.mongoDb.collection('user_activities').countDocuments();
            const mongoNotifications = await this.mongoDb.collection('notifications').countDocuments();
            const mongoChats = await this.mongoDb.collection('real_time_chats').countDocuments();

            console.log('📊 MongoDB Statistics:');
            console.log(`   - User Activities: ${mongoActivities}`);
            console.log(`   - Notifications: ${mongoNotifications}`);
            console.log(`   - Chat Conversations: ${mongoChats}`);

            // Step 3: Store aggregated analytics in MongoDB
            const analyticsDoc = await this.mongoDb.collection('analytics').insertOne({
                metric_type: 'cross_database_snapshot',
                timestamp: new Date(),
                mysql_metrics: {
                    total_users: mysqlData.total_users,
                    student_count: mysqlData.student_count,
                    lecturer_count: mysqlData.lecturer_count,
                    total_posts: mysqlData.total_posts,
                    total_events: mysqlData.total_events
                },
                mongodb_metrics: {
                    user_activities: mongoActivities,
                    notifications: mongoNotifications,
                    chat_conversations: mongoChats
                },
                summary: {
                    total_engagement: mysqlData.total_posts + mongoActivities,
                    hybrid_system_health: 'optimal'
                }
            });

            console.log(`✅ Analytics stored in MongoDB: ${analyticsDoc.insertedId}`);

        } catch (error) {
            console.error('❌ Analytics demo failed:', error);
        }
    }

    // DEMO 5: Data Synchronization Example
    async demoDataSynchronization() {
        console.log('\n🎯 DEMO 5: Data Synchronization Pattern');
        console.log('======================================');

        try {
            // Example: When a post gets high engagement in MongoDB, update MySQL
            const highEngagementPosts = await this.mongoDb.collection('user_activities')
                .aggregate([
                    { 
                        $match: { 
                            activity_type: 'post_engagement',
                            timestamp: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } // Last 24 hours
                        } 
                    },
                    { 
                        $group: { 
                            _id: '$mysql_post_id', 
                            engagement_count: { $sum: 1 } 
                        } 
                    },
                    { 
                        $match: { 
                            engagement_count: { $gte: 3 } // High engagement threshold
                        } 
                    }
                ]).toArray();

            console.log('🔄 High Engagement Posts (from MongoDB activities):');
            
            for (const post of highEngagementPosts) {
                // Update MySQL post with engagement count
                await this.mysqlConnection.execute(
                    `UPDATE posts SET upvote_count = upvote_count + ? WHERE post_id = ?`,
                    [post.engagement_count, post._id]
                );
                console.log(`   ✅ Updated MySQL post ${post._id} with +${post.engagement_count} engagements`);
            }

            console.log('📈 Data synchronization completed: MongoDB activities → MySQL post metrics');

        } catch (error) {
            console.error('❌ Synchronization demo failed:', error);
        }
    }

    async cleanup() {
        // Clean up demo data
        await this.mysqlConnection.execute(`DELETE FROM users WHERE username = 'demo.user'`);
        await this.mysqlConnection.execute(`DELETE FROM event_registrations WHERE user_id = (SELECT user_id FROM users WHERE username = 'demo.user')`);
        
        await this.mongoClient.close();
        await this.mysqlConnection.end();
        
        console.log('\n🧹 Demo data cleaned up');
    }
}

// Run the hybrid demonstration
async function runHybridDemo() {
    const hybridManager = new HybridDatabaseManager();
    
    try {
        await hybridManager.initialize();
        
        console.log('🚀 STARTING MYSQL + MONGODB HYBRID DEMONSTRATION');
        console.log('=================================================');

        // Run all demos
        const newUserId = await hybridManager.demoUserRegistration();
        await hybridManager.demoEventRegistration(newUserId);
        await hybridManager.demoRealTimeChat(newUserId);
        await hybridManager.demoCrossDatabaseAnalytics();
        await hybridManager.demoDataSynchronization();

        console.log('\n🎉 HYBRID DATABASE DEMONSTRATION COMPLETED SUCCESSFULLY!');
        console.log('======================================================');
        console.log('This demo showed:');
        console.log('✅ User registration flowing through both databases');
        console.log('✅ Event registration with cross-database references');
        console.log('✅ Real-time chat integrated with MySQL group context');
        console.log('✅ Cross-database analytics and reporting');
        console.log('✅ Data synchronization patterns');

    } catch (error) {
        console.error('💥 Hybrid demo failed:', error);
    } finally {
        await hybridManager.cleanup();
    }
}

// Execute if run directly
if (require.main === module) {
    runHybridDemo();
}

module.exports = HybridDatabaseManager;