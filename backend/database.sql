-- Create Database
CREATE DATABASE IF NOT EXISTS appdocu1;
USE appdocu1;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    uid VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- Added password field
    displayName VARCHAR(255),
    photoURL TEXT,
    bio TEXT,
    phoneNumber VARCHAR(20),
    isAdmin TINYINT(1) DEFAULT 0,
    createdAt BIGINT,
    lastActive BIGINT,
    sellerRatingAverage DOUBLE DEFAULT 0.0,
    sellerRatingCount INT DEFAULT 0
);

-- Followers Table (Many-to-Many relationship for users)
CREATE TABLE IF NOT EXISTS user_followers (
    followerId VARCHAR(255),
    followingId VARCHAR(255),
    PRIMARY KEY (followerId, followingId),
    FOREIGN KEY (followerId) REFERENCES users(uid) ON DELETE CASCADE,
    FOREIGN KEY (followingId) REFERENCES users(uid) ON DELETE CASCADE
);

-- Products Table
CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(255) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    imageUrls TEXT, -- JSON array of strings
    category VARCHAR(50),
    product_condition VARCHAR(50), -- 'condition' is a reserved keyword in some SQL versions
    status VARCHAR(50),
    ownerId VARCHAR(255),
    ownerName VARCHAR(255),
    ownerPhotoURL TEXT,
    location_lat DOUBLE,
    location_lng DOUBLE,
    locationAddress TEXT,
    createdAt BIGINT,
    updatedAt BIGINT,
    viewCount INT DEFAULT 0,
    tags TEXT, -- JSON array of strings
    FOREIGN KEY (ownerId) REFERENCES users(uid) ON DELETE CASCADE
);
