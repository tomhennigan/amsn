-- MySQL dump 10.10
--
-- Host: localhost    Database: www
-- ------------------------------------------------------
-- Server version	5.0.18-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `_email`
--

DROP TABLE IF EXISTS `_email`;
CREATE TABLE `_email` (
  `email_id` int(20) NOT NULL auto_increment,
  `email_to` char(50) NOT NULL,
  `email_subject` varchar(100) NOT NULL,
  `email_body` text NOT NULL,
  PRIMARY KEY  (`email_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `_email`
--


/*!40000 ALTER TABLE `_email` DISABLE KEYS */;
LOCK TABLES `_email` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `_email` ENABLE KEYS */;

--
-- Table structure for table `_sessions`
--

DROP TABLE IF EXISTS `_sessions`;
CREATE TABLE `_sessions` (
  `session_id` varchar(32) NOT NULL default '',
  `session_created` int(11) NOT NULL default '0',
  `session_active` int(11) NOT NULL default '0',
  `session_counter` int(11) NOT NULL default '0',
  `session_remote_address` varchar(128) NOT NULL default '',
  `session_data` longtext NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `_sessions`
--


/*!40000 ALTER TABLE `_sessions` DISABLE KEYS */;
LOCK TABLES `_sessions` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `_sessions` ENABLE KEYS */;

--
-- Table structure for table `amsn_langs`
--

DROP TABLE IF EXISTS `amsn_langs`;
CREATE TABLE `amsn_langs` (
  `lang_id` int(20) NOT NULL auto_increment,
  `lang_code` char(5) NOT NULL default 'en',
  `lang_key` char(20) NOT NULL,
  `lang_text` text NOT NULL,
  PRIMARY KEY  (`lang_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `amsn_langs`
--


/*!40000 ALTER TABLE `amsn_langs` DISABLE KEYS */;
LOCK TABLES `amsn_langs` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `amsn_langs` ENABLE KEYS */;

--
-- Table structure for table `amsn_menu`
--

DROP TABLE IF EXISTS `amsn_menu`;
CREATE TABLE `amsn_menu` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `men_id` varchar(40) NOT NULL default '',
  `men_url` varchar(255) NOT NULL default '',
  `men_pos` enum('0','1','2','3','4','5','6','7','8','9') default '9',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `men_id` (`men_id`,`men_url`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `amsn_menu`
--


/*!40000 ALTER TABLE `amsn_menu` DISABLE KEYS */;
LOCK TABLES `amsn_menu` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `amsn_menu` ENABLE KEYS */;

--
-- Table structure for table `amsn_news`
--

DROP TABLE IF EXISTS `amsn_news`;
CREATE TABLE `amsn_news` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `title` varchar(150) NOT NULL default '',
  `author` int(5) unsigned NOT NULL default '0',
  `text` text NOT NULL,
  `time` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  FULLTEXT KEY `text` (`text`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `amsn_news`
--


/*!40000 ALTER TABLE `amsn_news` DISABLE KEYS */;
LOCK TABLES `amsn_news` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `amsn_news` ENABLE KEYS */;

--
-- Table structure for table `amsn_poll`
--

DROP TABLE IF EXISTS `amsn_poll`;
CREATE TABLE `amsn_poll` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `question` varchar(150) NOT NULL default '',
  `time` int(10) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `question` (`question`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `amsn_poll`
--


/*!40000 ALTER TABLE `amsn_poll` DISABLE KEYS */;
LOCK TABLES `amsn_poll` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `amsn_poll` ENABLE KEYS */;

--
-- Table structure for table `amsn_poll_answers`
--

DROP TABLE IF EXISTS `amsn_poll_answers`;
CREATE TABLE `amsn_poll_answers` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `id_father` int(10) unsigned NOT NULL default '0',
  `answer` varchar(150) NOT NULL default '',
  `votes` int(5) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `amsn_poll_answers`
--


/*!40000 ALTER TABLE `amsn_poll_answers` DISABLE KEYS */;
LOCK TABLES `amsn_poll_answers` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `amsn_poll_answers` ENABLE KEYS */;

--
-- Table structure for table `amsn_poll_votes`
--

DROP TABLE IF EXISTS `amsn_poll_votes`;
CREATE TABLE `amsn_poll_votes` (
  `ip` varchar(100) NOT NULL default '',
  `time` int(10) NOT NULL default '0',
  `poll_id` int(10) NOT NULL default '0'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `amsn_poll_votes`
--


/*!40000 ALTER TABLE `amsn_poll_votes` DISABLE KEYS */;
LOCK TABLES `amsn_poll_votes` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `amsn_poll_votes` ENABLE KEYS */;

--
-- Table structure for table `amsn_screenshots`
--

DROP TABLE IF EXISTS `amsn_screenshots`;
CREATE TABLE `amsn_screenshots` (
  `id` int(10) NOT NULL auto_increment,
  `name` varchar(100) NOT NULL default '',
  `desc` varchar(255) NOT NULL default '',
  `screen` varchar(150) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `amsn_screenshots`
--


/*!40000 ALTER TABLE `amsn_screenshots` DISABLE KEYS */;
LOCK TABLES `amsn_screenshots` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `amsn_screenshots` ENABLE KEYS */;

--
-- Table structure for table `amsn_users`
--

DROP TABLE IF EXISTS `amsn_users`;
CREATE TABLE `amsn_users` (
  `id` int(5) unsigned NOT NULL auto_increment,
  `user` varchar(20) NOT NULL default '',
  `pass` varchar(40) NOT NULL default '',
  `email` varchar(50) NOT NULL default '',
  `level` enum('1','2','3','4','5') NOT NULL default '1',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `user` (`user`),
  UNIQUE KEY `email` (`email`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `amsn_users`
--


/*!40000 ALTER TABLE `amsn_users` DISABLE KEYS */;
LOCK TABLES `amsn_users` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `amsn_users` ENABLE KEYS */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

