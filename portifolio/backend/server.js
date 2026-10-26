require('dotenv').config();

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

const app = express();

app.set('trust proxy', 1);

const uploadsDirectory =
    process.env.UPLOADS_DIR || path.join(__dirname, 'uploads');
const postUploadsDirectory = path.join(uploadsDirectory, 'posts');
fs.mkdirSync(postUploadsDirectory, { recursive: true });

const allowedImageTypes = {
    'image/jpeg': '.jpg',
    'image/jpg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'image/bmp': '.bmp',
    'image/x-ms-bmp': '.bmp'
};

const allowedImageExtensions = {
    '.jpg': '.jpg',
    '.jpeg': '.jpg',
    '.jfif': '.jpg',
    '.png': '.png',
    '.gif': '.gif',
    '.webp': '.webp',
    '.bmp': '.bmp'
};

const postImageUpload = multer({
    storage: multer.diskStorage({
        destination: (req, file, callback) => {
            callback(null, postUploadsDirectory);
        },
        filename: (req, file, callback) => {
            const extension = allowedImageTypes[file.mimetype] ||
                allowedImageExtensions[path.extname(file.originalname).toLowerCase()];
            callback(null, `${Date.now()}-${require('crypto').randomUUID()}${extension}`);
        }
    }),
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (req, file, callback) => {
        const extension = path.extname(file.originalname).toLowerCase();
        if (!allowedImageTypes[file.mimetype] && !allowedImageExtensions[extension]) {
            return callback(new Error(
                `Unsupported image type "${file.mimetype || extension || 'unknown'}". ` +
                'Please choose a JPG, PNG, GIF, WebP or BMP image.'
            ));
        }
        callback(null, true);
    }
});

// ==========================================
// MIDDLEWARE
// ==========================================

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(uploadsDirectory));
app.use((req, res, next) => {
    if (req.method === 'POST' && req.path === '/api/login') {
        console.info('POST /api/login received');
        res.on('finish', () => {
            console.info(`POST /api/login completed with HTTP ${res.statusCode}`);
        });
    }
    next();
});

// ==========================================
// CONFIGURATION
// ==========================================

const PORT = process.env.PORT || 3000;

// ==========================================
// MYSQL CONNECTION
// ==========================================

const requiredDatabaseVariables = [
    'DB_HOST',
    'DB_USER',
    'DB_PASSWORD',
    'DB_NAME',
];
const missingDatabaseVariables = requiredDatabaseVariables.filter(
    (name) => !process.env[name]
);

if (missingDatabaseVariables.length > 0) {
    throw new Error(
        `Missing database environment variables: ${missingDatabaseVariables.join(', ')}`
    );
}

const db = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// ==========================================
// HOME
// ==========================================

app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'NeighbourConnect backend is running!'
    });
});

// ==========================================
// TEST MYSQL CONNECTION
// ==========================================

app.get('/api/test', async (req, res) => {
    try {
        const [rows] = await db.query(
            'SELECT 1 AS test'
        );

        res.json({
            success: true,
            message: 'Node.js is connected to MySQL!',
            database: rows
        });

    } catch (error) {
        console.error('MySQL test error:', error);

        res.status(500).json({
            success: false,
            message: 'Database connection failed'
        });
    }
});

// ==========================================
// REGISTER USER
// ==========================================

app.post('/api/register', async (req, res) => {
    try {
        const {
            name,
            email,
            password,
            phone
        } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Name, email and password are required'
            });
        }

        const [existingUser] = await db.query(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (existingUser.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Email already registered'
            });
        }

        const [result] = await db.query(
            `INSERT INTO users
            (name, email, password, phone)
            VALUES (?, ?, ?, ?)`,
            [
                name,
                email,
                password,
                phone || null
            ]
        );

        res.status(201).json({
            success: true,
            message: 'Account created successfully',
            userId: result.insertId
        });

    } catch (error) {
        console.error('Register error:', error);

        res.status(500).json({
            success: false,
            message: 'Registration failed'
        });
    }
});

// ==========================================
// LOGIN USER
// ==========================================

app.post('/api/login', async (req, res) => {
    try {
        const {
            email,
            password
        } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email and password are required'
            });
        }

        const [users] = await db.query(
            `SELECT
                id,
                name,
                email,
                phone,
                profile_image,
                neighbourhood_id
             FROM users
             WHERE email = ? AND password = ?`,
            [
                email,
                password
            ]
        );

        if (users.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }

        res.json({
            success: true,
            message: 'Login successful',
            user: users[0]
        });

    } catch (error) {
        console.error('Login error:', error);

        res.status(500).json({
            success: false,
            message: 'Login failed'
        });
    }
});

// ==========================================
// GET USER PROFILE
// ==========================================

app.get('/api/profile/:id', async (req, res) => {
    try {
        const userId = req.params.id;

        const [users] = await db.query(
            `SELECT
                id,
                name,
                email,
                phone,
                profile_image,
                neighbourhood_id,
                created_at
             FROM users
             WHERE id = ?`,
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        res.json({
            success: true,
            message: 'Profile loaded successfully',
            user: users[0]
        });

    } catch (error) {
        console.error('Profile error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to load profile'
        });
    }
});

// ==========================================
// GET ALL USERS
// ==========================================

app.get('/api/users', async (req, res) => {
    try {
        const [users] = await db.query(
            `SELECT
                id,
                name,
                email,
                phone,
                profile_image,
                neighbourhood_id,
                created_at
             FROM users
             ORDER BY name ASC`
        );

        res.json({
            success: true,
            users: users
        });

    } catch (error) {
        console.error('Users error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to load users'
        });
    }
});

// ==========================================
// GET ALL NEIGHBOURHOODS
// ==========================================

app.get('/api/neighbourhoods', async (req, res) => {
    try {
        const [neighbourhoods] = await db.query(
            `SELECT
                id,
                name,
                city,
                description,
                created_at
             FROM neighbourhoods
             ORDER BY name ASC`
        );

        res.json({
            success: true,
            neighbourhoods: neighbourhoods
        });

    } catch (error) {
        console.error('Neighbourhood error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to load neighbourhoods'
        });
    }
});

// ==========================================
// UPDATE USER NEIGHBOURHOOD
// ==========================================

app.put('/api/users/:id/neighbourhood', async (req, res) => {
    try {
        const userId = req.params.id;
        const { neighbourhood_id } = req.body;

        if (!neighbourhood_id) {
            return res.status(400).json({
                success: false,
                message: 'neighbourhood_id is required'
            });
        }

        const [neighbourhood] = await db.query(
            `SELECT id
             FROM neighbourhoods
             WHERE id = ?`,
            [neighbourhood_id]
        );

        if (neighbourhood.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Neighbourhood not found'
            });
        }

        const [result] = await db.query(
            `UPDATE users
             SET neighbourhood_id = ?
             WHERE id = ?`,
            [
                neighbourhood_id,
                userId
            ]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        res.json({
            success: true,
            message: 'Neighbourhood updated successfully'
        });

    } catch (error) {
        console.error('Update neighbourhood error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to update neighbourhood'
        });
    }
});

// ==========================================
// GET POSTS
// ==========================================

app.get('/api/posts/:neighbourhoodId', async (req, res) => {
    try {
        const neighbourhoodId = Number(req.params.neighbourhoodId);
        const userId = Number(req.query.user_id || 0);

        if (!Number.isInteger(neighbourhoodId)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid neighbourhood ID'
            });
        }

        console.log(
            `Loading posts: neighbourhood=${neighbourhoodId}, user=${userId}`
        );

        const [posts] = await db.query(
            `
            SELECT
                p.id,
                p.user_id,
                p.neighbourhood_id,
                p.category,
                p.content,
                p.image_url,
                p.created_at,

                u.name AS user_name,
                u.profile_image,

                (
                    SELECT COUNT(*)
                    FROM likes l
                    WHERE l.post_id = p.id
                ) AS likes_count,

                (
                    SELECT COUNT(*)
                    FROM comments c
                    WHERE c.post_id = p.id
                ) AS comments_count,

                CASE
                    WHEN EXISTS (
                        SELECT 1
                        FROM likes l2
                        WHERE l2.post_id = p.id
                        AND l2.user_id = ?
                    )
                    THEN 1
                    ELSE 0
                END AS user_liked

            FROM posts p

            LEFT JOIN users u
                ON p.user_id = u.id

            WHERE p.neighbourhood_id = ?

            ORDER BY p.created_at DESC
            `,
            [
                userId,
                neighbourhoodId
            ]
        );

        console.log(`Posts found: ${posts.length}`);

        return res.status(200).json({
            success: true,
            posts: posts
        });

    } catch (error) {

        // IMPORTANT:
        // Print the REAL MySQL error in terminal
        console.error('====================================');
        console.error('GET POSTS ERROR');
        console.error('====================================');
        console.error('Code:', error.code);
        console.error('Message:', error.message);
        console.error('SQL:', error.sql);
        console.error('====================================');

        return res.status(500).json({
            success: false,
            message: 'Failed to load posts',

            // Temporary debugging information
            error: error.message,
            code: error.code
        });
    }
});
// ==========================================
// CREATE POST
// ==========================================

app.post('/api/posts', async (req, res) => {
    try {
        const {
            user_id,
            neighbourhood_id,
            category,
            content,
            image_url
        } = req.body;

        if (
            !user_id ||
            !neighbourhood_id ||
            !category ||
            !content
        ) {
            return res.status(400).json({
                success: false,
                message:
                    'user_id, neighbourhood_id, category and content are required'
            });
        }

        const [result] = await db.query(
            `INSERT INTO posts
            (
                user_id,
                neighbourhood_id,
                category,
                content,
                image_url
            )
            VALUES (?, ?, ?, ?, ?)`,
            [
                user_id,
                neighbourhood_id,
                category,
                content,
                image_url || null
            ]
        );

        res.status(201).json({
            success: true,
            message: 'Post created successfully',
            postId: result.insertId
        });

    } catch (error) {
        console.error('Create post error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to create post'
        });
    }
});
// ==========================================
// LIKE POST
// ==========================================

app.post('/api/posts/:postId/like', async (req, res) => {
    try {
        const postId = req.params.postId;
        const { user_id } = req.body;

        if (!user_id) {
            return res.status(400).json({
                success: false,
                message: 'user_id is required'
            });
        }

        // Check post exists
        const [posts] = await db.query(
            'SELECT id FROM posts WHERE id = ?',
            [postId]
        );

        if (posts.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Post not found'
            });
        }

        // Check if already liked
        const [existingLike] = await db.query(
            `SELECT id
             FROM likes
             WHERE post_id = ?
             AND user_id = ?`,
            [
                postId,
                user_id
            ]
        );

        if (existingLike.length > 0) {
            return res.json({
                success: true,
                message: 'Post already liked'
            });
        }

        // Add like
        await db.query(
            `INSERT INTO likes
            (post_id, user_id)
            VALUES (?, ?)`,
            [
                postId,
                user_id
            ]
        );

        // Get new count
        const [count] = await db.query(
            `SELECT COUNT(*) AS likes_count
             FROM likes
             WHERE post_id = ?`,
            [postId]
        );

        res.status(201).json({
            success: true,
            message: 'Post liked successfully',
            likes_count: count[0].likes_count
        });

    } catch (error) {
        console.error('Like post error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to like post'
        });
    }
});
// ==========================================
// UNLIKE POST
// ==========================================

app.delete('/api/posts/:postId/like', async (req, res) => {
    try {
        const postId = req.params.postId;
        const { user_id } = req.body;

        if (!user_id) {
            return res.status(400).json({
                success: false,
                message: 'user_id is required'
            });
        }

        await db.query(
            `DELETE FROM likes
             WHERE post_id = ?
             AND user_id = ?`,
            [
                postId,
                user_id
            ]
        );

        // Get new count
        const [count] = await db.query(
            `SELECT COUNT(*) AS likes_count
             FROM likes
             WHERE post_id = ?`,
            [postId]
        );

        res.json({
            success: true,
            message: 'Post unliked successfully',
            likes_count: count[0].likes_count
        });

    } catch (error) {
        console.error('Unlike post error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to unlike post'
        });
    }
});
// ==========================================
// GET COMMENTS
// ==========================================

app.get('/api/posts/:postId/comments', async (req, res) => {
    try {
        const postId = req.params.postId;

        const [comments] = await db.query(
            `SELECT
                c.id,
                c.post_id,
                c.user_id,
                c.content,
                c.created_at,
                u.name AS user_name,
                u.profile_image
             FROM comments c

             LEFT JOIN users u
                ON c.user_id = u.id

             WHERE c.post_id = ?

             ORDER BY c.created_at ASC`,
            [postId]
        );

        res.json({
            success: true,
            comments: comments
        });

    } catch (error) {
        console.error('Get comments error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to load comments'
        });
    }
});
// ==========================================
// ADD COMMENT
// ==========================================

app.post('/api/posts/:postId/comments', async (req, res) => {
    try {
        const postId = req.params.postId;
        const {
            user_id,
            content
        } = req.body;

        if (!user_id || !content || !content.trim()) {
            return res.status(400).json({
                success: false,
                message: 'user_id and content are required'
            });
        }

        // Check post exists
        const [posts] = await db.query(
            'SELECT id FROM posts WHERE id = ?',
            [postId]
        );

        if (posts.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Post not found'
            });
        }

        const [result] = await db.query(
            `INSERT INTO comments
            (
                post_id,
                user_id,
                content
            )
            VALUES (?, ?, ?)`,
            [
                postId,
                user_id,
                content.trim()
            ]
        );

        // Get newly created comment
        const [comments] = await db.query(
            `SELECT
                c.id,
                c.post_id,
                c.user_id,
                c.content,
                c.created_at,
                u.name AS user_name,
                u.profile_image
             FROM comments c

             LEFT JOIN users u
                ON c.user_id = u.id

             WHERE c.id = ?`,
            [result.insertId]
        );

        res.status(201).json({
            success: true,
            message: 'Comment added successfully',
            comment: comments[0]
        });

    } catch (error) {
        console.error('Add comment error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to add comment'
        });
    }
});

// ==========================================
// GET EVENTS
// ==========================================

app.get('/api/events/:neighbourhoodId', async (req, res) => {
    try {
        const neighbourhoodId = req.params.neighbourhoodId;

        const [events] = await db.query(
            `SELECT
                e.id,
                e.title,
                e.description,
                e.neighbourhood_id,
                e.organizer_id,
                e.location,
                e.event_date,
                e.image_url,
                e.created_at,
                u.name AS organizer_name
             FROM events e
             LEFT JOIN users u
                ON e.organizer_id = u.id
             WHERE e.neighbourhood_id = ?
             ORDER BY e.event_date ASC`,
            [neighbourhoodId]
        );

        res.json({
            success: true,
            events: events
        });

    } catch (error) {
        console.error('Get events error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to load events'
        });
    }
});

// ==========================================
// CREATE EVENT
// ==========================================

app.post('/api/events', async (req, res) => {
    try {
        const {
            title,
            description,
            neighbourhood_id,
            organizer_id,
            location,
            event_date,
            image_url
        } = req.body;

        if (
            !title ||
            !neighbourhood_id ||
            !organizer_id ||
            !event_date
        ) {
            return res.status(400).json({
                success: false,
                message:
                    'title, neighbourhood_id, organizer_id and event_date are required'
            });
        }

        const [result] = await db.query(
            `INSERT INTO events
            (
                title,
                description,
                neighbourhood_id,
                organizer_id,
                location,
                event_date,
                image_url
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [
                title,
                description || null,
                neighbourhood_id,
                organizer_id,
                location || null,
                event_date,
                image_url || null
            ]
        );

        res.status(201).json({
            success: true,
            message: 'Event created successfully',
            eventId: result.insertId
        });

    } catch (error) {
        console.error('Create event error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to create event'
        });
    }
});

// ==========================================
// GET ISSUES
// ==========================================

app.get('/api/issues/:neighbourhoodId', async (req, res) => {
    try {
        const neighbourhoodId = req.params.neighbourhoodId;

        const [issues] = await db.query(
            `SELECT
                i.id,
                i.user_id,
                i.neighbourhood_id,
                i.category,
                i.title,
                i.description,
                i.image_url,
                i.latitude,
                i.longitude,
                i.status,
                i.created_at,
                u.name AS user_name
             FROM issues i
             LEFT JOIN users u
                ON i.user_id = u.id
             WHERE i.neighbourhood_id = ?
             ORDER BY i.created_at DESC`,
            [neighbourhoodId]
        );

        res.json({
            success: true,
            issues: issues
        });

    } catch (error) {
        console.error('Get issues error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to load issues'
        });
    }
});

// ==========================================
// CREATE ISSUE
// ==========================================

app.post('/api/issues', async (req, res) => {
    try {
        const {
            user_id,
            neighbourhood_id,
            category,
            title,
            description,
            image_url,
            latitude,
            longitude
        } = req.body;

        if (
            !user_id ||
            !neighbourhood_id ||
            !category ||
            !title
        ) {
            return res.status(400).json({
                success: false,
                message:
                    'user_id, neighbourhood_id, category and title are required'
            });
        }

        const [result] = await db.query(
            `INSERT INTO issues
            (
                user_id,
                neighbourhood_id,
                category,
                title,
                description,
                image_url,
                latitude,
                longitude
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                user_id,
                neighbourhood_id,
                category,
                title,
                description || null,
                image_url || null,
                latitude ?? null,
                longitude ?? null
            ]
        );

        res.status(201).json({
            success: true,
            message: 'Issue created successfully',
            issueId: result.insertId
        });

    } catch (error) {
        console.error('Create issue error:', error);

        res.status(500).json({
            success: false,
            message: 'Failed to create issue'
        });
    }
});

// ==========================================
// START SERVER
// ==========================================


app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});


// ==========================================
// UPLOAD POST IMAGE
// ==========================================

app.post('/api/uploads/posts', (req, res) => {
    postImageUpload.single('image')(req, res, (error) => {
        if (error) {
            return res.status(400).json({
                success: false,
                message: error.message || 'Image upload failed'
            });
        }

        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'An image file is required'
            });
        }

        const imageUrl = `${req.protocol}://${req.get('host')}/uploads/posts/${req.file.filename}`;
        return res.status(201).json({
            success: true,
            imageUrl,
            image_url: imageUrl
        });
    });
});