-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 03, 2024 at 04:10 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `project_mobile`
--

-- --------------------------------------------------------

--
-- Table structure for table `booking`
--

CREATE TABLE `booking` (
  `book_id` int(11) NOT NULL,
  `user_id` varchar(10) NOT NULL,
  `room_id` int(11) NOT NULL,
  `time` varchar(50) NOT NULL,
  `objective` varchar(50) NOT NULL,
  `approve_name` varchar(100) NOT NULL,
  `booking_status` int(11) NOT NULL COMMENT '1=pending,2=approve,3=disapprove',
  `date` date NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `booking`
--

INSERT INTO `booking` (`book_id`, `user_id`, `room_id`, `time`, `objective`, `approve_name`, `booking_status`, `date`) VALUES
(1, '6531501167', 2, '10:00 - 12:00', 'Meeting', '-', 1, '2024-11-02');

-- --------------------------------------------------------

--
-- Table structure for table `room`
--

CREATE TABLE `room` (
  `room_id` int(11) NOT NULL,
  `room_number` varchar(10) NOT NULL,
  `description` text NOT NULL,
  `image` varchar(255) NOT NULL,
  `slot1` int(11) NOT NULL COMMENT '0=close,1=free,2=pending,3=reserved',
  `slot2` int(11) NOT NULL,
  `slot3` int(11) NOT NULL,
  `slot4` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `room`
--

INSERT INTO `room` (`room_id`, `room_number`, `description`, `image`, `slot1`, `slot2`, `slot3`, `slot4`) VALUES
(1, '101', '3 - 5 people with Wi-Fi, air conditioning, projector screen and whiteboard', 'assets/images/room101.jpg', 0, 3, 2, 3),
(2, '102', '5 - 10 people with Wi-Fi, air conditioning, projector screen and whiteboard', 'assets/images/room102.jpg', 0, 3, 1, 1),
(3, '103', '4 - 8 people with Wi-Fi, air conditioning, projector screen and whiteboard', 'assets/images/room103.jpg', 0, 0, 2, 1);

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `user_id` varchar(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` int(11) NOT NULL COMMENT '1=student,2=staff,3=lecturer'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`user_id`, `name`, `username`, `password`, `role`) VALUES
('6531501100', 'Test Student', 'Student2', '$2b$10$oYomC9Btrw6vrNXNa1.mMOaSFSoIW6gkfWoHwyKstpjP8irCArJY.', 1),
('6531501167', 'Daw Rung', 'Student1', '$2b$10$OZOARxyLf57uQn3.eaQc2u54w5G9bprIf2lsIF3ss0JmHqrGhnIFy', 1),
('Lect001', 'Aj.Jaidee Jung', 'Lecturer1', '$2b$10$bPykeqmLjDD6YELznas7LeCIGIoLXpGDUON/PdZv3ERwK10fzCMpq', 3),
('Lect002', 'Aj.K Kub', 'Lecturer2', '$2b$10$bPykeqmLjDD6YELznas7LeCIGIoLXpGDUON/PdZv3ERwK10fzCMpq', 3),
('Staff001', 'Kukkai', 'Staff1', '$2b$10$9J7I2888H4xbGeAaKi4AeuUzIqE8qNn73tB7e2FqLb7tEA52vRRju', 2);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `booking`
--
ALTER TABLE `booking`
  ADD PRIMARY KEY (`book_id`),
  ADD KEY `fk_user` (`user_id`),
  ADD KEY `fk_room` (`room_id`);

--
-- Indexes for table `room`
--
ALTER TABLE `room`
  ADD PRIMARY KEY (`room_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `booking`
--
ALTER TABLE `booking`
  MODIFY `book_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `room`
--
ALTER TABLE `room`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `booking`
--
ALTER TABLE `booking`
  ADD CONSTRAINT `fk_room` FOREIGN KEY (`room_id`) REFERENCES `room` (`room_id`),
  ADD CONSTRAINT `fk_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
