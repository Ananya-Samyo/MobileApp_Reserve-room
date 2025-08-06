process.env.TZ = 'Asia/Bangkok';
    const express = require('express');
    const path = require('path');
    const bcrypt = require("bcrypt");
    const session = require('express-session');
    const MemoryStore = require('memorystore')(session);
    const con = require('./config/db');
    const app = express();
    const moment = require('moment-timezone');
    const { promisify } = require('util');
    require('./public/js/resetRoomStatus');
    require('./public/js/updateSlot');


    app.use('/public', express.static(path.join(__dirname, 'public')));
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));
    app.use(session({
        cookie: { maxAge: 24 * 60 * 60 * 1000 },
        secret: 'webappwebjai',
        resave: false,
        saveUninitialized: true,
        store: new MemoryStore({
            checkPeriod: 24 * 60 * 60 * 1000
        })
    }));

    // ------------- Create hashed password --------------
    app.get("/password/:pass", function (req, res) {
        const password = req.params.pass;
        const saltRounds = 10;
        bcrypt.hash(password, saltRounds, function (err, hash) {
            if (err) {
                return res.status(500).send("Hashing error");
            }
            res.send(hash);
        });
    });



    // ---------- Home page -------------
    app.get('/', function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/homepage.html'));
    });

    // ----------- Login ----------------
    app.get('/logingin', function (req, res) {
        res.sendFile(__dirname + '/views/login.html');
    });

    app.post('/login', function (req, res) {
        const { stu_id, password } = req.body;
        const sql = "SELECT user_Id, password, role, name FROM user WHERE stu_id = ?";
        con.query(sql, [stu_id], function (err, results) {
            if (err) {
                console.error(err);
                return res.status(500).send("Server error");
            }
            if (results.length !== 1) {
                return res.status(401).send("Login fail");
            }

            bcrypt.compare(password, results[0].password, function (err, same) {
                if (err) {
                    return res.status(500).send("Server error");
                }
                if (same) {
                    req.session.userID = results[0].user_id;
                    req.session.stu_id = stu_id;
                    req.session.role = results[0].role;
                    req.session.name = results[0].name; // Store the user's name in the session

                    let redirectURL = '/';
                    if (results[0].role == 0) {
                        redirectURL = '/homepage';
                    } else if (results[0].role == 1) {
                        redirectURL = '/lecturedashboard';
                    } else if (results[0].role == 2) {
                        redirectURL = '/staffdashboard';
                    }

                    res.json({ success: true, redirectURL: redirectURL });
                } else {
                    res.status(401).send("Wrong password");
                };
            });
        });
    });

    // --------------- register -------------------
    app.get('/registration', function (req, res) {
        res.sendFile(__dirname + '/views/register.html');
    });

    app.post('/register', function (req, res) {
        const { name, stu_id, password } = req.body;

        if (password.length < 6) {
            return res.status(401).send("Password should be at least 6 characters long");
        }

        const findStudentIdQuery = 'SELECT * FROM user WHERE stu_id = ?';
        con.query(findStudentIdQuery, [stu_id], function (err, studentResults) {
            if (err) {
                console.error(err);
                return res.status(500).send("Server error!");
            }

            if (studentResults.length > 0) {
                return res.status(401).send("Student ID has already been used!");
            }

            bcrypt.hash(password, 10, function (err, hash) {
                if (err) {
                    console.error(err);
                    return res.status(500).send("Hash error!");
                }

                const insertUserQuery = "INSERT INTO user (name, stu_id, password, role) VALUES (?, ?, ?, 0)";
                con.query(insertUserQuery, [name, stu_id, hash], function (err, insertResult) {
                    if (err) {
                        console.error(err);
                        return res.status(500).send("Server error inserting data!");
                    }

                    res.status(200).send("User registered successfully");
                });
            });
        });
    });

    // ------------- GET User info --------------
    app.get('/user', function (req, res) {
        res.json({
            "user_ID": req.session.userID,
            "stu_id": req.session.stu_id,
            "name": req.session.name,
            "role": req.session.role
        });
    });

    // ---------------- Student ----------------------------------
    app.get('/homepage', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/user_home.html'));
    });

    // Room List Student
    app.get('/smallroom', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/user_room1.html'));
    });

    app.get('/smallroomlist', function (req, res) {
        const sql = "SELECT * FROM room WHERE room_type = 0";
        con.query(sql, function (err, results) {
            if (err) {
                // console.log(sql);
                console.error(err);
                return res.status(500).send("Database server error");
            }
            res.json(results);
        });
    });

    app.get('/largeroom', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/user_room2.html'));
    });

    app.get('/largeroomlist', function (req, res) {
        const sql = "SELECT * FROM room WHERE room_type = 1";
        con.query(sql, function (err, results) {
            if (err) {
                // console.log(sql);
                console.error(err);
                return res.status(500).send("Database server error");
            }
            res.json(results);
        });
    });

    // Student request
    app.get('/request', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/user_request.html'));
    });

    app.post('/book', async (req, res) => {
        const { room_ID, date, time, objective } = req.body;
        const user_ID = req.session.stu_id;

        try {
            // Convert the date to Asia/Bangkok timezone and format it
            const formattedDate = moment(date).tz('Asia/Bangkok').format('YYYY-MM-DD');
    
            // Check if the booking date matches today's date
            if (formattedDate !== today) {
                console.log(formattedDate);
                return res.status(400).json({ error: 'Booking date must be today' });
            }
            // Check if the user has already booked a room for the given date
            const checkBookingSql = 'SELECT * FROM booking WHERE stu_id = ? AND date = ? LIMIT 1';
            const checkBookingQuery = promisify(con.query).bind(con);
            const checkResult = await checkBookingQuery(checkBookingSql, [user_ID, date]);

            if (checkResult.length > 0) {
                return res.status(400).json({ error: 'You have already booked a room for today' });
            }

            // If the user hasn't booked a room for the given date, proceed with inserting the new booking
            const insertBookingSql = 'INSERT INTO booking (stu_id, room_ID, date, time, objective, booking_status) VALUES (?, ?, ?, ?, ?, 2)';
            const insertBookingQuery = promisify(con.query).bind(con);
            const bookingResult = await insertBookingQuery(insertBookingSql, [user_ID, room_ID, date, time, objective]);

            // Check if the booking was inserted successfully
            if (bookingResult.affectedRows !== 1) {
                console.error('Failed to insert booking');
                return res.status(500).json({ error: 'Failed to insert booking' });
            }

            // Prepare the SQL query to update the room's time slot status
            const updateRoomQuery = `UPDATE room SET ${getTimeSlotField(time)} = '2' WHERE room_ID = ?`;
            const updateRoomQueryAsync = promisify(con.query).bind(con);
            const roomUpdateResult = await updateRoomQueryAsync(updateRoomQuery, [room_ID]);

            // Check if the room's time slot status was updated successfully
            if (roomUpdateResult.affectedRows !== 1) {
                console.error('Failed to update room status');
                return res.status(500).json({ error: 'Failed to update room status' });
            }

            // Send a success response
            res.status(200).json({ message: 'Booking request submitted successfully' });
        } catch (error) {
            console.error('Error processing booking:', error);
            res.status(500).json({ error: 'An error occurred while processing your request' });
        }
    });

    // Function to determine the appropriate time slot status field based on the selected time
    function getTimeSlotField(time) {
        switch (time) {
            case '08:00 - 10:00':
                return 'slot1_status';
            case '10:00 - 12:00':
                return 'slot2_status';
            case '13:00 - 15:00':
                return 'slot3_status';
            case '15:00 - 17:00':
                return 'slot4_status';
            default:
                throw new Error('Invalid time slot');
        }
    }

    // Route handler to get room info
    app.get('/room_info', (req, res) => {
        // Extract room ID from the query parameters
        const roomID = req.query.room_ID;

        const roomQuery = "SELECT room_name, description FROM room WHERE room_ID = ?";

        con.query(roomQuery, [roomID], (error, results) => {
            if (error) {
                console.error('Error querying database: ' + error.stack);
                res.status(500).send('Error querying database');
                return;
            }

            if (results.length === 0) {
                res.status(404).send('Room not found');
                return;
            }

            // Send room info as JSON
            res.json(results[0]);
        });
    });

    // Check status
    app.get('/check', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/user_check.html'));
    });
    const today = moment().tz('Asia/Bangkok').format('YYYY-MM-DD');

    app.get('/showstatus', function (req, res) {
        const userID = req.session.stu_id;

        if (!userID) {
            return res.status(401).send("Unauthorized");
        }

        const sql = "SELECT room.room_name, booking.date, booking.time, booking.approve_name, booking.booking_status, booking.objective FROM booking INNER JOIN room ON booking.room_ID = room.room_ID WHERE stu_id = ? AND DATE(date) = ?"; // Fetch bookings for today
        con.query(sql, [userID, today], function (err, results) {
            if (err) {
                console.error(err);
                return res.status(500).send("Database server error");
            }
            res.json(results);
        });
    });


    // Student History
    app.get('/history', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/user_history.html'));
    });

    app.get('/showhistory', function (req, res) {
        let sql = "SELECT booking.objective, room.room_name, booking.date, booking.time, booking.booking_status, booking.approve_name FROM booking INNER JOIN room ON booking.room_ID = room.room_ID WHERE stu_id = ? AND (booking.booking_status = 1 OR booking.booking_status = 0)";

        const { year, month } = req.query;
        const params = [req.session.stu_id];

        if (year && month) {
            sql += " AND YEAR(booking.date) = ? AND MONTH(booking.date) = ?";
            params.push(year, month);
        } else if (year) {
            sql += " AND YEAR(booking.date) = ?";
            params.push(year);
        } else if (month) {
            sql += " AND MONTH(booking.date) = ?";
            params.push(month);
        }

        con.query(sql, params, function (err, results) {
            if (err) {
                console.error(err);
                return res.status(500).send("Database server error");
            }

            // Convert the results to a JSON array
            const jsonResults = results.map(result => ({
                objective: result.objective,
                room_name: result.room_name,
                date: result.date,
                time: result.time,
                booking_status: result.booking_status,
                approve_name: result.approve_name
            }));

            res.json(jsonResults);
        });
    });

    // ---------------- Lecturers --------------------------
    // Lecturer Dashboard
    app.get('/lecturedashboard', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/lect_dash.html'));
    });
    app.get('/counts', (req, res) => {
        // Query to get counts
        const query = `
            SELECT 
                SUM(total_slots) AS total_slots,
                SUM(free_slots) AS free_slots,
                SUM(pending_slots) AS pending_slots,
                SUM(reserved_slots) AS reserved_slots,
                SUM(disabled_slots) AS disabled_slots
            FROM (
                SELECT 
                    COUNT(*) AS total_slots,
                    SUM(CASE WHEN slot1_status = 1 THEN 1 ELSE 0 END) AS free_slots,
                    SUM(CASE WHEN slot1_status = 2 THEN 1 ELSE 0 END) AS pending_slots,
                    SUM(CASE WHEN slot1_status = 3 THEN 1 ELSE 0 END) AS reserved_slots,
                    SUM(CASE WHEN slot1_status = 0 THEN 1 ELSE 0 END) AS disabled_slots
                FROM room
                UNION ALL
                SELECT 
                    COUNT(*),
                    SUM(CASE WHEN slot2_status = 1 THEN 1 ELSE 0 END),
                    SUM(CASE WHEN slot2_status = 2 THEN 1 ELSE 0 END),
                    SUM(CASE WHEN slot2_status = 3 THEN 1 ELSE 0 END),
                    SUM(CASE WHEN slot2_status = 0 THEN 1 ELSE 0 END)
                FROM room
                UNION ALL
                SELECT 
                    COUNT(*),
                    SUM(CASE WHEN slot3_status = 1 THEN 1 ELSE 0 END),
                    SUM(CASE WHEN slot3_status = 2 THEN 1 ELSE 0 END),
                    SUM(CASE WHEN slot3_status = 3 THEN 1 ELSE 0 END),
                    SUM(CASE WHEN slot3_status = 0 THEN 1 ELSE 0 END)
                FROM room
                UNION ALL
                SELECT 
                    COUNT(*),
                    SUM(CASE WHEN slot4_status = 1 THEN 1 ELSE 0 END),
                    SUM(CASE WHEN slot4_status = 2 THEN 1 ELSE 0 END),
                    SUM(CASE WHEN slot4_status = 3 THEN 1 ELSE 0 END),
                    SUM(CASE WHEN slot4_status = 0 THEN 1 ELSE 0 END)
                FROM room
            ) AS slot_counts;
        `;

        // Execute the query and send counts data as JSON response
        con.query(query, (error, results) => {
            if (error) {
                console.error('Error fetching counts:', error);
                res.status(500).json({ error: 'Error fetching counts' });
                return;
            }

            res.json(results[0]);
        });
    });

    // Lecturer Room list
    app.get('/lectsmallroom', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/lect_room1.html'));
    });
    app.get('/lectsmallroomlist', function (req, res) {
        const sql = "SELECT * FROM room WHERE room_type = 0";
        con.query(sql, function (err, results) {
            if (err) {
                // console.log(sql);
                console.error(err);
                return res.status(500).send("Database server error");
            }
            res.json(results);
        });
    });


    app.get('/lectlargeroom', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/lect_room2.html'));
    });
    app.get('/lectlargeroomlist', function (req, res) {
        const sql = "SELECT * FROM room WHERE room_type = 1";
        con.query(sql, function (err, results) {
            if (err) {
                // console.log(sql);
                console.error(err);
                return res.status(500).send("Database server error");
            }
            res.json(results);
        });
    });

    // lecturer request
    app.get('/booking', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/lect_request.html'));
    });
    app.get('/bookingrequest', function (req, res) {
        const sql = "SELECT booking.booking_id,user.name, room.room_name, booking.stu_id, booking.date, booking.time, booking.objective FROM booking INNER JOIN user ON booking.stu_id = user.stu_id INNER JOIN room ON booking.room_ID = room.room_ID WHERE booking.booking_status = 2 AND DATE(booking.date) = CURDATE();";
        con.query(sql, function (err, results) {
            if (err) {
                // console.log(sql);
                console.error(err);
                return res.status(500).send("Database server error");
            }
            res.json(results);
        });
    });

    app.put('/approve-booking/:booking_id', async (req, res) => {
        const bookingId = req.params.booking_id;
        const sql = 'SELECT room_ID, time FROM booking WHERE booking_id = ?';
        con.query(sql, [bookingId], async (err, results) => {
            if (err) {
                console.error(err);
                return res.status(500).send("Database server error");
            }
            if (results.length !== 1) {
                return res.status(500).send('Booking not found');
            }
    
            const { room_ID, time } = results[0];
            const updateStatus = await updateRoomStatus(room_ID, time, 3); 
    
            if (updateStatus) {
                const updateBookingStatusSql = 'UPDATE booking SET booking_status = 1, approve_name = ? WHERE booking_id = ?';
                const approveName = req.session.name; 

                con.query(updateBookingStatusSql, [approveName, bookingId], (err, results) => {
                    if (err) {
                        console.error(err);
                        return res.status(500).send("Database server error");
                    }
                    if (results.affectedRows !== 1) {
                        return res.status(500).send('Failed to update booking status');
                    }
                    res.send('Booking approved!');
                });
            } else {
                res.status(500).send('Failed to update room status');
            }
        });
    });

    app.put('/reject-booking/:booking_id', async (req, res) => {
        const bookingId = req.params.booking_id;
        const sql = 'SELECT room_ID, time FROM booking WHERE booking_id = ?';
        con.query(sql, [bookingId], async (err, results) => {
            if (err) {
                console.error(err);
                return res.status(500).send("Database server error");
            }
            if (results.length !== 1) {
                return res.status(500).send('Booking not found');
            }

            const { room_ID, time } = results[0];
            const updateStatus = await updateRoomStatus(room_ID, time, 1); // 1 for free

            if (updateStatus) {
                const updateBookingStatusSql = 'UPDATE booking SET booking_status = 0, approve_name = ? WHERE booking_id = ?';
                const disapproveName = req.session.name;

                con.query(updateBookingStatusSql, [disapproveName, bookingId], (err, results) => {
                    if (err) {
                        console.error(err);
                        return res.status(500).send("Database server error");
                    }
                    if (results.affectedRows !== 1) {
                        return res.status(500).send('Failed to update booking status');
                    }
                    res.send('Booking rejected!');
                });
            } else {
                res.status(500).send('Failed to update room status');
            }
        });
    });

    const updateRoomStatus = async (roomID, time, status) => {
        try {
            const slotField = getTimeSlotField(time);
            const updateRoomQuery = `UPDATE room SET ${slotField} = ? WHERE room_ID = ?`;
            const updateRoomQueryAsync = promisify(con.query).bind(con);
            const roomUpdateResult = await updateRoomQueryAsync(updateRoomQuery, [status, roomID]);
    
            return roomUpdateResult.affectedRows === 1;
        } catch (error) {
            console.error('Error updating room status:', error);
            return false;
        }
    };
    

    app.get('/lecturehistory', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/lect_his.html'));
    });

    app.get('/showlecturehistory', function (req, res) {
        let sql = "SELECT booking.stu_id, booking.objective, room.room_name, booking.date, booking.time, booking.booking_status FROM booking INNER JOIN room ON booking.room_ID = room.room_ID WHERE approve_name = ? AND booking.booking_status IN (1, 0)";
    
        const { year, month } = req.query;
        const params = [req.session.name];
    
        if (year && month) {
        sql += " AND YEAR(booking.date) = ? AND MONTH(booking.date) = ?";
        params.push(year, month);
        } else if (year) {
        sql += " AND YEAR(booking.date) = ?";
        params.push(year);
        } else if (month) {
        sql += " AND MONTH(booking.date) = ?";
        params.push(month);
        }
    
        con.query(sql, params, function (err, results) {
        if (err) {
            console.error(err);
            return res.status(500).json({ error: "Database server error" });
        }
    
        // Convert the results to a JSON array
        const jsonResults = results.map(result => ({
            stu_id: result.stu_id,
            objective: result.objective,
            room_name: result.room_name,
            date: result.date,
            time: result.time,
            booking_status: result.booking_status
        }));
    
        res.json(jsonResults);
        });
    });








    // ----------------- Staff ---------------------------

    // Staff Dashboard
    app.get('/staffdashboard', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/staff_dash.html'));
    });

    // Staff Room list
    app.get('/staffroom', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/staff_room1.html'));
    });
    app.get('/staffroomlist', function (req, res) {
        const sql = "SELECT * FROM room WHERE room_type = 0";
        con.query(sql, function (err, results) {
            if (err) {
                // console.log(sql);
                console.error(err);
                return res.status(500).send("Database server error");
            }
            res.json(results);
        });
    });

    app.get('/staffrooms', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/staff_room2.html'));
    });
    app.get('/staffroomslist', function (req, res) {
        const sql = "SELECT * FROM room WHERE room_type = 1";
        con.query(sql, function (err, results) {
            if (err) {
                // console.log(sql);
                console.error(err);
                return res.status(500).send("Database server error");
            }
            res.json(results);
        });
    });

    // Add Room
    // Route to add a small room 
    app.post('/addroom', (req, res) => {
        // Prepare SQL query
        const sql = `INSERT INTO room (room_type, room_name, description, slot1_status, slot2_status, slot3_status, slot4_status) 
                    VALUES (?, ?, ?, 1, 1, 1, 1)`;
        const values = [0, req.body.roomName, req.body.description];

        // Execute query
        con.query(sql, values, (err, result) => {
            if (err) {
                console.error('Error adding room: ' + err.message);
                res.status(500).send('Error adding room');
            } else {
                console.log('Room added successfully');
                res.status(200).send('Room added successfully');
            }
        });
    });

    // Route to add a large room 
    app.post('/addroom2', (req, res) => {
        // Prepare SQL query
        const sql = `INSERT INTO room (room_type, room_name, description, slot1_status, slot2_status, slot3_status, slot4_status) 
                    VALUES (?, ?, ?, 1, 1, 1, 1)`;
        const values = [1, req.body.roomName, req.body.description];

        // Execute query
        con.query(sql, values, (err, result) => {
            if (err) {
                console.error('Error adding room: ' + err.message);
                res.status(500).send('Error adding room');
            } else {
                console.log('Room added successfully');
                res.status(200).send('Room added successfully');
            }
        });
    });

    // Route to disable a slot
    app.post('/disableSlot', (req, res) => {
        const { roomId, slotNumber } = req.body;
    
        // Update slot status in the room table
        const query = `UPDATE room SET slot${slotNumber}_status = 0 WHERE room_ID = ?`;
    
        con.query(query, [roomId], (error, results, fields) => {
        if (error) {
            console.error('Error updating slot status: ' + error.message);
            res.status(500).send('Error updating slot status: ' + error.message);
            return;
        }
        //   console.log(`Slot ${slotNumber} disabled for room ${roomId}`);
        res.sendStatus(200); // OK
        });
    });

    //   Edit room description
    app.get('/room/:roomId', (req, res) => {
        const roomId = req.params.roomId;
        const sql = 'SELECT room_name, description FROM room WHERE room_ID = ?';
        con.query(sql, [roomId], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Error fetching room details');
        }
        if (results.length === 0) {
            return res.status(404).send('Room not found');
        }
        res.json(results[0]);
        });
    });
    // Update room description route
    app.put('/updateRoomDescription/:roomId', (req, res) => {
        const roomId = req.params.roomId; // Extract room ID from URL parameter
        if (!roomId) {
        return res.status(400).send('Room ID is missing');
        }
        const newDescription = req.body.description;
        if (!newDescription) {
        return res.status(400).send('New description is missing');
        }
        // console.log('Updating room', roomId, 'with description:', newDescription);
        const sql = 'UPDATE room SET description = ? WHERE room_ID = ?';
        con.query(sql, [newDescription, roomId], (error, results) => {
        if (error) {
            console.error(error);
            return res.status(500).send('Error updating room description');
        }
        if (results.affectedRows === 0) {
            return res.status(404).send('Room not found');
        }
        res.status(200).send('Room description updated');
        });
    });

    
    
    
    // Staff History
    app.get('/staffhistory', isAuthenticated, function (_req, res) {
        res.sendFile(path.join(__dirname, 'views/staff_his.html'));
    });

    app.get('/historyoflectures', function (req, res) {
        let sql = "SELECT booking.booking_id, booking.stu_id, booking.room_ID, booking.date, booking.objective, booking.booking_status, booking.approve_name, room.room_name, booking.time FROM booking INNER JOIN room ON booking.room_ID = room.room_ID WHERE booking.booking_status IN (1, 0)";

        const { year, month } = req.query;
        const params = [];

        if (year && month) {
            sql += " AND YEAR(booking.date) = ? AND MONTH(booking.date) = ?";
            params.push(year, month);
        } else if (year) {
            sql += " AND YEAR(booking.date) = ?";
            params.push(year);
        } else if (month) {
            sql += " AND MONTH(booking.date) = ?";
            params.push(month);
        }

        con.query(sql, params, function (err, results) {
            if (err) {
                console.error(err);
                return res.status(500).send("Database server error");
            }

            // Convert the results to a JSON array
            const jsonResults = results.map(result => ({
                booking_id: result.booking_id,
                stu_id: result.stu_id,
                room_ID: result.room_ID,
                date: result.date,
                objective: result.objective,
                booking_status: result.booking_status,
                approve_name: result.approve_name,
                room_name: result.room_name,
                time: result.time
            }));

            res.json(jsonResults);
        });
    });

    function isAuthenticated(req, res, next) {
        if (req.session.stu_id) {
            // User is authenticated, proceed to the next middleware
            next();
        } else {
            // User is not authenticated, redirect to login page
            res.redirect('/logingin');
        }
    }
    // ------------- Logout --------------
    app.get("/logout", function (req, res) {
        //clear session variable
        req.session.destroy(function (err) {
            if (err) {
                console.error(err);
                res.status(500).send("Cannot clear session");
            }
            else {
                res.redirect("/");
            }
        });
    });

    // Show port
    const port = process.env.PORT || 3000;
    app.listen(port, function () {
        console.log("Server is ready at port " + port);
    });
