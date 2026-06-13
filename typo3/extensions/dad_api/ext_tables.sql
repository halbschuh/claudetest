--
-- Table structure for historical locations (Orte)
--
CREATE TABLE tx_dadapi_domain_model_ort (
    uid INT(11) NOT NULL AUTO_INCREMENT,
    pid INT(11) NOT NULL DEFAULT 0,
    tstamp INT(11) NOT NULL DEFAULT 0,
    crdate INT(11) NOT NULL DEFAULT 0,
    deleted TINYINT(1) NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,

    name VARCHAR(255) NOT NULL DEFAULT '',
    description TEXT,
    latitude DECIMAL(10, 7) NOT NULL DEFAULT 0.0000000,
    longitude DECIMAL(10, 7) NOT NULL DEFAULT 0.0000000,
    historical_period VARCHAR(100) DEFAULT NULL,
    thumbnail INT(11) NOT NULL DEFAULT 0,
    lexikon_slugs TEXT,

    PRIMARY KEY (uid),
    KEY parent (pid)
);

--
-- Table structure for Dann & Jetzt image pairs
--
CREATE TABLE tx_dadapi_domain_model_dannundjetzt (
    uid INT(11) NOT NULL AUTO_INCREMENT,
    pid INT(11) NOT NULL DEFAULT 0,
    tstamp INT(11) NOT NULL DEFAULT 0,
    crdate INT(11) NOT NULL DEFAULT 0,
    deleted TINYINT(1) NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,

    ort_uid INT(11) NOT NULL DEFAULT 0,
    historical_image INT(11) NOT NULL DEFAULT 0,
    modern_image INT(11) NOT NULL DEFAULT 0,
    caption TEXT,
    historical_year SMALLINT(4) DEFAULT NULL,
    modern_year SMALLINT(4) DEFAULT NULL,

    PRIMARY KEY (uid),
    KEY parent (pid),
    KEY ort (ort_uid)
);

--
-- Table structure for thematic walks (Spaziergänge)
--
CREATE TABLE tx_dadapi_domain_model_spaziergang (
    uid INT(11) NOT NULL AUTO_INCREMENT,
    pid INT(11) NOT NULL DEFAULT 0,
    tstamp INT(11) NOT NULL DEFAULT 0,
    crdate INT(11) NOT NULL DEFAULT 0,
    deleted TINYINT(1) NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,

    title VARCHAR(255) NOT NULL DEFAULT '',
    description TEXT,
    duration_minutes SMALLINT(4) NOT NULL DEFAULT 0,
    distance_meters INT(11) NOT NULL DEFAULT 0,
    cover_image INT(11) NOT NULL DEFAULT 0,
    tags VARCHAR(500) DEFAULT '',

    PRIMARY KEY (uid),
    KEY parent (pid)
);

--
-- Table structure for waypoints
--
CREATE TABLE tx_dadapi_domain_model_wegpunkt (
    uid INT(11) NOT NULL AUTO_INCREMENT,
    pid INT(11) NOT NULL DEFAULT 0,
    deleted TINYINT(1) NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,

    spaziergang_uid INT(11) NOT NULL DEFAULT 0,
    latitude DECIMAL(10, 7) NOT NULL DEFAULT 0.0000000,
    longitude DECIMAL(10, 7) NOT NULL DEFAULT 0.0000000,
    title VARCHAR(255) NOT NULL DEFAULT '',
    body_text TEXT,
    audio_file INT(11) NOT NULL DEFAULT 0,
    sort_order INT(11) NOT NULL DEFAULT 0,

    PRIMARY KEY (uid),
    KEY spaziergang (spaziergang_uid)
);

--
-- Table structure for user-submitted photos
--
CREATE TABLE tx_dadapi_domain_model_userfoto (
    uid INT(11) NOT NULL AUTO_INCREMENT,
    pid INT(11) NOT NULL DEFAULT 0,
    tstamp INT(11) NOT NULL DEFAULT 0,
    crdate INT(11) NOT NULL DEFAULT 0,
    deleted TINYINT(1) NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,

    fe_user_uid INT(11) NOT NULL DEFAULT 0,
    uploader_name VARCHAR(255) DEFAULT '',
    location_description TEXT,
    latitude DECIMAL(10, 7) DEFAULT NULL,
    longitude DECIMAL(10, 7) DEFAULT NULL,
    ort_uid INT(11) NOT NULL DEFAULT 0,
    image INT(11) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',

    PRIMARY KEY (uid),
    KEY parent (pid),
    KEY status (status)
);
