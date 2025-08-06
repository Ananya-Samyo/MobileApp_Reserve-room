const express = require('express');
const bcrypt = require('bcrypt');
const session = require('express-session');
const cron = require('node-cron');
const app = express();
const con = require('./db');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(session({
    secret: 'mobileapp',
    resave: false,
    saveUninitialized: true,
    cookie: { maxAge: 24 * 60 * 60 * 1000 }
}));

// Reset the time slot (How to check '* * * * *')
cron.schedule('0 0 * * *', () => {
    const resetSlotsQuery = `UPDATE room SET slot1 = 1, slot2 = 1, slot3 = 1, slot4 = 1`;

    con.query(resetSlotsQuery, (err, result) => {
        if (err) {
            console.error('Error resetting slots:', err);
        } else {
            console.log('All room slots have been reset to free status.');
        }
    });
});

// Close the slot after time
const resetSlots = (slot) => {
    const query = `UPDATE room SET ${slot} = 0 WHERE ${slot} = 1`;
    con.query(query, (err, result) => {
        if (err) {
            console.error(`Error resetting ${slot}:`, err);
        } else {
            console.log(`Successfully reset ${slot} slots.`);
        }
    });
};

cron.schedule('0 8 * * *', () => { // Reset slot1 from 1 to 0 at 08:00
    console.log('Resetting slot1 at 08:00');
    resetSlots('slot1');
});

cron.schedule('0 10 * * *', () => { // Reset slot2 from 1 to 0 at 10:00
    console.log('Resetting slot2 at 10:00');
    resetSlots('slot2');
});

cron.schedule('0 13 * * *', () => { // Reset slot3 from 1 to 0 at 13:00
    console.log('Resetting slot3 at 13:00');
    resetSlots('slot3');
});

cron.schedule('0 15 * * *', () => { // Reset slot4 from 1 to 0 at 15:00
    console.log('Resetting slot4 at 15:00');
    resetSlots('slot4');
});




app.post('/login', (req, res) => {
    const { username, password } = req.body;

    const query = 'SELECT * FROM user WHERE username = ?';
    con.query(query, [username], (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }

        if (results.length === 0) {
            return res.status(401).json({ message: 'Invalid username' });
        }

        const user = results[0];

        // Compare the password with the hashed password in the database
        bcrypt.compare(password, user.password, (err, isMatch) => {
            if (err) {
                return res.status(500).json({ message: 'Error comparing passwords' });
            }

            if (!isMatch) {
                return res.status(401).json({ message: 'Invalid password' });
            }

            // Store user_id in session
            req.session.user_id = user.user_id;



            res.json({
                message: 'Login successful',
                role: user.role,
                user_id: user.user_id,
            });


        });
    });
});



app.post('/register', function (req, res) {
    const { user_id, name, username, password } = req.body;

    const findStudentQuery = 'SELECT * FROM user WHERE username = ?';
    con.query(findStudentQuery, [username], function (err, studentResults) {
        if (err) {
            console.error(err);
            return res.status(500).send("Server error!");
        }

        if (studentResults.length > 0) {
            return res.status(401).send("Username has already been used!");
        }

        bcrypt.hash(password, 10, function (err, hash) {
            if (err) {
                console.error(err);
                return res.status(500).send("Hash error!");
            }

            const insertUserQuery = "INSERT INTO user (user_id, name, username, password, role) VALUES (?, ?, ?, ?, 1)";
            con.query(insertUserQuery, [user_id, name, username, hash], function (err, insertResult) {
                if (err) {
                    console.error(err);
                    return res.status(500).send("Server error inserting data!");
                }

                res.status(200).send("User registered successfully");
            });
        });
    });
});

// -------------------------Student----------------------------------
// Room List
app.get('/roomlist/student', function (req, res) {
    const sql = "SELECT * FROM room";
    con.query(sql, function (err, results) {
        if (err) {
            console.error(err);
            return res.status(500).send("Database server error");
        }

        // Map the results to match your front-end structure
        const rooms = results.map(room => ({
            room_id: room.room_id,
            room: room.room_number,
            description: room.description,
            image: room.image,
            slot1: room.slot1,
            slot2: room.slot2,
            slot3: room.slot3,
            slot4: room.slot4,
        }));

        res.json(rooms);
    });
});


// Booking
app.post('/booking', function (req, res) {
    const { user_id, room_id, time, objective } = req.body;

    const today = new Date().toISOString().split('T')[0];



    // Check if user has already booked today
    const checkQuery = `SELECT * FROM booking WHERE user_id = ? AND date = ?`;
    con.query(checkQuery, [user_id, today], (err, result) => {
        if (err) return res.status(500).send('Database error');

        if (result.length > 0) {
            return res.status(400).send('You can only book once per day');
        }

        // Insert new booking
        const insertQuery = `INSERT INTO booking (user_id, room_id, time, objective, approve_name, booking_status, date) VALUES (?, ?, ?, ?, '-', 1, ?)`;
        con.query(insertQuery, [user_id, room_id, time, objective, today], (err, insertResult) => {
            if (err) return res.status(500).send('Failed to book room');

            // Update room slot status to pending
            const slotField = `slot${['8:00 - 10:00', '10:00 - 12:00', '13:00 - 15:00', '15:00 - 17:00'].indexOf(time) + 1}`;
            const updateQuery = `UPDATE room SET ${slotField} = 2 WHERE room_id = ?`;
            con.query(updateQuery, [room_id], (err) => {
                if (err) return res.status(500).send('Failed to update slot status');

                res.send('Booking successful');
            });
        });
    });
});

// Check Status
app.get('/check', function (req, res) {
    const userID = req.query.user_id;

    if (!userID) {
        return res.status(401).send("Unauthorized");
    }

    const today = new Date().toISOString().slice(0, 10);

    const sql = `
        SELECT
            room.room_number, 
            booking.time, 
            booking.approve_name, 
            booking.booking_status, 
            booking.objective
        FROM 
            booking 
        INNER JOIN 
            room ON booking.room_id = room.room_id 
        WHERE 
            booking.user_id = ? 
            AND booking.date = ?
    `;

    con.query(sql, [userID, today], function (err, results) {
        if (err) {
            console.error('Database server error:', err);
            return res.status(500).send("Database server error");
        }

        // Check if no results found for today
        if (results.length === 0) {
            return res.status(404).send("No bookings found for today");
        }

        // Return the results if bookings are found
        res.json(results);
    });
});



// History
app.get('/student/history', (req, res) => {
    const userId = req.query.user_id;

    const sql = `
        SELECT 
            DATE_FORMAT(booking.date, '%Y-%m-%d') AS date,
            booking.time, 
            booking.approve_name, 
            booking.booking_status, 
            room.image, 
            room.room_number
        FROM 
            booking 
        JOIN 
            room ON booking.room_id = room.room_id 
        WHERE 
            booking.booking_status IN ('2', '3') 
            AND booking.user_id = ? ORDER BY date DESC;
    `;

    con.query(sql, [userId], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Database query error' });
        }

        res.json(results);
    });
});



// -------------------------Staff----------------------------------
// Room List
app.get('/roomlist/staff', function (req, res) {
    const sql = "SELECT * FROM room";
    con.query(sql, function (err, results) {
        if (err) {
            // console.log(sql);
            console.error(err);
            return res.status(500).send("Database server error");
        }

        const rooms = results.map(room => ({
            room_id: room.room_id,
            room: room.room_number,
            description: room.description,
            image: room.image,
            slot1: room.slot1,
            slot2: room.slot2,
            slot3: room.slot3,
            slot4: room.slot4,
        }));

        res.json(rooms);
    });
});

// Dashboard
app.get('/staff/dashboard', (req, res) => {
    const query = `
        SELECT 
            SUM(free_slots) AS free_slots,
            SUM(pending_slots) AS pending_slots,
            SUM(reserved_slots) AS reserved_slots,
            SUM(disabled_slots) AS disabled_slots
        FROM (
            SELECT 
                SUM(CASE WHEN slot1 = 1 THEN 1 ELSE 0 END) AS free_slots,
                SUM(CASE WHEN slot1 = 2 THEN 1 ELSE 0 END) AS pending_slots,
                SUM(CASE WHEN slot1 = 3 THEN 1 ELSE 0 END) AS reserved_slots,
                SUM(CASE WHEN slot1 = 0 THEN 1 ELSE 0 END) AS disabled_slots
            FROM room
            UNION ALL
            SELECT 
                SUM(CASE WHEN slot2 = 1 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot2 = 2 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot2 = 3 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot2 = 0 THEN 1 ELSE 0 END)
            FROM room
            UNION ALL
            SELECT 
                SUM(CASE WHEN slot3 = 1 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot3 = 2 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot3 = 3 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot3 = 0 THEN 1 ELSE 0 END)
            FROM room
            UNION ALL
            SELECT 
                SUM(CASE WHEN slot4 = 1 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot4 = 2 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot4 = 3 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot4 = 0 THEN 1 ELSE 0 END)
            FROM room
        ) AS slot_counts;
    `;

    con.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }

        res.json(results[0]);
    });
});

const multer = require('multer');
const path = require('path');

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Set up storage for Multer
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/'); // Folder where the uploaded files will be stored
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + path.extname(file.originalname)); // Rename file to prevent conflicts
    }
});

// Initialize Multer with the storage configuration
const upload = multer({ storage: storage });
// Add Room
// Add Room
app.post('/addroom', upload.single('image'), (req, res) => {
    const { room_number, description } = req.body;
    const imagePath = req.file ? 'uploads/' + req.file.filename : null; // Get the filename of the uploaded image

    // Validate input
    if (!room_number || !description) {
        return res.status(400).json({ error: 'Room number and description are required' });
    }

    if (!imagePath) {
        return res.status(400).json({ error: 'Image is required' });
    }

    // Get the current time
    const currentTime = new Date();
    const hours = currentTime.getHours();  // Get current hour

    // Set default slot values
    let slot1 = 1, slot2 = 1, slot3 = 1, slot4 = 1;

    // Update slots based on the time
    if (hours >= 15) {
        slot1 = 0;
        slot2 = 0;
        slot3 = 0;
        slot4 = 0;
    } else if (hours >= 13) {
        slot1 = 0;
        slot2 = 0;
    } else if (hours >= 10) {
        slot1 = 0;
        slot2 = 0;
    } else if (hours >= 8) {
        slot1 = 0;
    }

    // Insert room data into the database
    const sql = `INSERT INTO room (room_number, description, image, slot1, slot2, slot3, slot4) 
                 VALUES (?, ?, ?, ?, ?, ?, ?)`;
    const values = [room_number, description, imagePath, slot1, slot2, slot3, slot4];

    con.query(sql, values, (err, result) => {
        if (err) {
            console.error('Error inserting room data:', err);
            return res.status(500).json({ error: 'Database error' });
        }
        res.status(201).json({ message: 'Room added successfully' });
    });
});



// Edit
app.put('/edit', upload.single('image'), (req, res) => {
    const { room_id, description } = req.body;
    const imagePath = req.file ? 'uploads/' + req.file.filename : null; // Use the relative path for the image

    // Validate input
    if (!room_id) {
        return res.status(400).json({ error: 'Room ID is required' });
    }

    // Build the update query dynamically
    const updates = [];
    const values = [];

    if (description) {
        updates.push('description = ?');
        values.push(description);
    }

    if (imagePath) {
        updates.push('image = ?');
        values.push(imagePath);
    }

    if (updates.length === 0) {
        return res
            .status(400)
            .json({ error: 'At least one of description or image must be provided to update.' });
    }

    // Add room_id to the values array for the WHERE clause
    values.push(room_id);

    // Create the SQL query
    const sql = `
        UPDATE room 
        SET ${updates.join(', ')} 
        WHERE room_id = ?
    `;

    // Execute the query
    con.query(sql, values, (err, result) => {
        if (err) {
            console.error('Error updating room:', err);
            return res.status(500).json({ error: 'Database error' });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Room not found' });
        }

        res.json({ message: 'Room details updated successfully' });
    });
});



// Disable
app.post('/disable', (req, res) => {
    const { room_id, selectedTimeSlot } = req.body;


    let slotColumn;
    switch (selectedTimeSlot) {
        case '8:00 - 10:00':
            slotColumn = 'slot1';
            break;
        case '10:00 - 12:00':
            slotColumn = 'slot2';
            break;
        case '13:00 - 15:00':
            slotColumn = 'slot3';
            break;
        case '15:00 - 17:00':
            slotColumn = 'slot4';
            break;
        default:
            return res.status(400).json({ error: 'Invalid time slot' });
    }


    const checkSlotQuery = `SELECT ${slotColumn} FROM room WHERE room_id = ?`;
    con.query(checkSlotQuery, [room_id], (err, result) => {
        if (err || result.length === 0) {
            return res.status(404).json({ error: 'Room not found' });
        }


        if (result[0][slotColumn] !== 1) {
            return res.status(400).json({ error: 'Slot is not available for disabling' });
        }


        const updateSlotQuery = `UPDATE room SET ${slotColumn} = 0 WHERE room_id = ?`;
        con.query(updateSlotQuery, [room_id], (err, result) => {
            if (err || result.affectedRows === 0) {
                return res.status(500).json({ error: 'Failed to disable slot' });
            }

            res.json({ message: 'Slot disabled successfully' });
        });
    });
});


// History
app.get('/staff/history', (req, res) => {
    const query = `
        SELECT b.room_id, b.user_id, DATE_FORMAT(b.date, '%Y-%m-%d') AS date, b.time, b.approve_name, b.booking_status, r.image, r.room_number
        FROM booking b
        JOIN room r ON b.room_id = r.room_id
        WHERE b.booking_status IN (2, 3)
        ORDER BY b.date DESC;
    `;

    con.query(query, (err, results) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).send("Database query failed.");
        }

        if (results.length === 0) {
            return res.status(404).send("No reservations found.");
        }

        const reservations = results.map(row => ({
            room: `Room ${row.room_number}`,
            reservationId: row.user_id,
            date: row.date,
            time: row.time,
            approver: row.approve_name,
            isApproved: row.booking_status === 2,
            imagePath: row.image
        }));

        res.json(reservations);
    });
});








// -------------------------Lecturer----------------------------------
// Room List
app.get('/roomlist/lecturer', function (req, res) {
    const sql = "SELECT * FROM room";
    con.query(sql, function (err, results) {
        if (err) {
            // console.log(sql);
            console.error(err);
            return res.status(500).send("Database server error");
        }
        const rooms = results.map(room => ({
            room: room.room_number,
            description: room.description,
            image: room.image,
            slot1: room.slot1,
            slot2: room.slot2,
            slot3: room.slot3,
            slot4: room.slot4,
        }));

        res.json(rooms);
    });
});

// See the booking request
app.get('/request', (req, res) => {
    const query = `
    SELECT 
      booking.book_id, 
      booking.user_id,  
      booking.room_id, 
      room.room_number, 
      booking.time, 
      booking.objective, 
      booking.booking_status, 
      DATE_FORMAT(booking.date, '%Y-%m-%d') AS formatted_date
    FROM booking 
    JOIN room ON booking.room_id = room.room_id
    WHERE booking.date = CURDATE()
      AND booking.booking_status = 1`;

    con.query(query, (err, results) => {
        if (err) {
            console.error('Error fetching booking requests:', err);
            res.status(500).json({ error: 'Failed to fetch booking requests' });
        } else {
            res.json(results);
        }
    });
});


// Approve
app.post('/approve', (req, res) => {
    const lecturerId = req.body.user_id;
    const { book_id } = req.body;

    // Verify the user has a lecturer role and retrieve their name
    const userQuery = 'SELECT name, role FROM user WHERE user_id = ?';
    con.query(userQuery, [lecturerId], (err, result) => {
        if (err || result.length === 0 || result[0].role !== 3) {
            return res.status(403).json({ error: 'Unauthorized access' });
        }

        const approveName = result[0].name; // Lecturer's name

        // Retrieve booking details, including room_id and time (to determine slot)
        const bookingQuery = `
            SELECT room_id, time 
            FROM booking 
            WHERE book_id = ? AND booking_status = 1`;

        con.query(bookingQuery, [book_id], (err, bookingResult) => {
            if (err || bookingResult.length === 0) {
                return res.status(404).json({ error: 'Booking not found or already processed' });
            }

            const { room_id, time } = bookingResult[0];
            const slotNumber = getSlotNumberFromTime(time); // Helper function to map time to slot

            // Update booking status to approved and add approve_name
            const approveQuery = `
                UPDATE booking 
                SET booking_status = 2, approve_name = ? 
                WHERE book_id = ?`;

            con.query(approveQuery, [approveName, book_id], (err, result) => {
                if (err || result.affectedRows === 0) {
                    return res.status(500).json({ error: 'Failed to approve booking' });
                }

                // Update the corresponding slot in the room table to reserved (3)
                const updateSlotQuery = `UPDATE room SET slot${slotNumber} = 3 WHERE room_id = ?`;

                con.query(updateSlotQuery, [room_id], (err, result) => {
                    if (err || result.affectedRows === 0) {
                        return res.status(500).json({ error: 'Failed to update room slot' });
                    }
                    res.json({ message: 'Booking approved and room slot updated' });
                });
            });
        });
    });
});

// Disapprove
app.post('/disapprove', (req, res) => {
    const lecturerId = req.body.user_id; // Logged-in lecturer's ID
    const { book_id } = req.body; // Expecting book_id in request body

    // Check if the user has a lecturer role and get their name
    const userQuery = 'SELECT name, role FROM user WHERE user_id = ?';
    con.query(userQuery, [lecturerId], (err, result) => {
        if (err || result.length === 0 || result[0].role !== 3) {
            return res.status(403).json({ error: 'Unauthorized access' });
        }

        const lecturerName = result[0].name; // Get lecturer's name

        // Retrieve booking details including room_id and time (to determine slot)
        const bookingQuery = `
            SELECT room_id, time 
            FROM booking 
            WHERE book_id = ? AND booking_status = 1`;

        con.query(bookingQuery, [book_id], (err, bookingResult) => {
            if (err || bookingResult.length === 0) {
                return res.status(404).json({ error: 'Booking not found or already processed' });
            }

            const { room_id, time } = bookingResult[0];
            const slotNumber = getSlotNumberFromTime(time); // Helper function to map time to slot

            // Update booking status to disapproved and add approve_name
            const disapproveQuery = `
                UPDATE booking 
                SET booking_status = 3, approve_name = ? 
                WHERE book_id = ?`;

            con.query(disapproveQuery, [lecturerName, book_id], (err, result) => {
                if (err || result.affectedRows === 0) {
                    return res.status(500).json({ error: 'Failed to disapprove booking' });
                }

                // Update the corresponding slot in the room table to free (1)
                const updateSlotQuery = `UPDATE room SET slot${slotNumber} = 1 WHERE room_id = ?`;

                con.query(updateSlotQuery, [room_id], (err, result) => {
                    if (err || result.affectedRows === 0) {
                        return res.status(500).json({ error: 'Failed to update room slot' });
                    }
                    res.json({ message: 'Booking disapproved and room slot updated' });
                });
            });
        });
    });
});


function getSlotNumberFromTime(time) {
    switch (time) {
        case '08:00 - 10:00': return 1;
        case '10:00 - 12:00': return 2;
        case '13:00 - 15:00': return 3;
        case '15:00 - 17:00': return 4;
        default: return null;
    }
}


// Dashboard
app.get('/lecturer/dashboard', (req, res) => {
    const query = `
        SELECT 
            SUM(free_slots) AS free_slots,
            SUM(pending_slots) AS pending_slots,
            SUM(reserved_slots) AS reserved_slots,
            SUM(disabled_slots) AS disabled_slots
        FROM (
            SELECT 
                SUM(CASE WHEN slot1 = 1 THEN 1 ELSE 0 END) AS free_slots,
                SUM(CASE WHEN slot1 = 2 THEN 1 ELSE 0 END) AS pending_slots,
                SUM(CASE WHEN slot1 = 3 THEN 1 ELSE 0 END) AS reserved_slots,
                SUM(CASE WHEN slot1 = 0 THEN 1 ELSE 0 END) AS disabled_slots
            FROM room
            UNION ALL
            SELECT 
                SUM(CASE WHEN slot2 = 1 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot2 = 2 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot2 = 3 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot2 = 0 THEN 1 ELSE 0 END)
            FROM room
            UNION ALL
            SELECT 
                SUM(CASE WHEN slot3 = 1 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot3 = 2 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot3 = 3 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot3 = 0 THEN 1 ELSE 0 END)
            FROM room
            UNION ALL
            SELECT 
                SUM(CASE WHEN slot4 = 1 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot4 = 2 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot4 = 3 THEN 1 ELSE 0 END),
                SUM(CASE WHEN slot4 = 0 THEN 1 ELSE 0 END)
            FROM room
        ) AS slot_counts;
    `;

    con.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ message: 'Database query error' });
        }

        res.json(results[0]);
    });
});

// History
app.get('/lecturer/history', (req, res) => {
    const userId = req.query.user_id;

    const sql = `
        SELECT 
            booking.user_id,
            DATE_FORMAT(booking.date, '%Y-%m-%d') AS date,
            booking.time, 
            booking.booking_status, 
            room.image, 
            room.room_number
        FROM 
            booking 
        JOIN 
            room ON booking.room_id = room.room_id 
        JOIN 
            user ON booking.approve_name = user.name  
        WHERE 
            booking.booking_status IN ('2', '3') 
            AND user.user_id = ? ORDER BY date DESC;
    `;

    con.query(sql, [userId], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Database query error' });
        }

        res.json(results);
    });
});



app.listen(3000, function () {
    console.log('Server is running at port 3000');
});