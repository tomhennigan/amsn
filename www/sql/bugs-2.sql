-- MySQL dump 10.10
--
-- Host: localhost    Database: bugs
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
-- Table structure for table `blocked`
--

DROP TABLE IF EXISTS `blocked`;
CREATE TABLE `blocked` (
  `block_id` int(20) NOT NULL auto_increment,
  `block_ip` char(15) NOT NULL default '',
  `block_until` int(20) NOT NULL default '0',
  PRIMARY KEY  (`block_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `blocked`
--


/*!40000 ALTER TABLE `blocked` DISABLE KEYS */;
LOCK TABLES `blocked` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `blocked` ENABLE KEYS */;

--
-- Table structure for table `bugreports`
--

DROP TABLE IF EXISTS `bugreports`;
CREATE TABLE `bugreports` (
  `bug_id` int(20) NOT NULL auto_increment,
  `bug_date` int(10) NOT NULL default '0',
  `bug_text` varchar(255) NOT NULL default '',
  `bug_stack` text NOT NULL,
  `bug_code` varchar(20) NOT NULL default '',
  `bug_amsn` varchar(5) NOT NULL default '',
  `bug_cvsdate` int(20) NOT NULL default '0',
  `bug_tcl` varchar(10) NOT NULL default '',
  `bug_tk` varchar(10) NOT NULL default '',
  `bug_os` varchar(20) NOT NULL default '',
  `bug_osversion` varchar(20) NOT NULL default '',
  `bug_byteorder` set('littleEndian','bigEndian') NOT NULL default '',
  `bug_threaded` set('true','false') NOT NULL default 'false',
  `bug_machine` varchar(20) NOT NULL default '',
  `bug_platform` set('windows','macintosh','unix') NOT NULL default '',
  `bug_user` varchar(255) NOT NULL default '',
  `bug_wordsize` int(10) NOT NULL default '0',
  `bug_status` text NOT NULL,
  `bug_protocol` text NOT NULL,
  `bug_ip` varchar(15) NOT NULL default '',
  `bug_email` varchar(100) NOT NULL default '',
  `bug_comment` text NOT NULL,
  `bug_msnprotocol` int(4) NOT NULL,
  `bug_parent` int(20) NOT NULL,
  PRIMARY KEY  (`bug_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `bugreports`
--


/*!40000 ALTER TABLE `bugreports` DISABLE KEYS */;
LOCK TABLES `bugreports` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `bugreports` ENABLE KEYS */;

--
-- Table structure for table `bugs`
--

DROP TABLE IF EXISTS `bugs`;
CREATE TABLE `bugs` (
  `bug_id` int(20) NOT NULL auto_increment,
  `bug_name` varchar(50) NOT NULL default 'New Bug',
  `bug_developer` char(50) NOT NULL default 'Nobody',
  `bug_priority` int(1) NOT NULL,
  `bug_last_update` int(20) NOT NULL,
  `bug_flag` int(2) NOT NULL,
  `bug_error_regexp` text NOT NULL,
  `bug_stack_regexp` text NOT NULL,
  `bug_desc` text NOT NULL,
  PRIMARY KEY  (`bug_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `bugs`
--


/*!40000 ALTER TABLE `bugs` DISABLE KEYS */;
LOCK TABLES `bugs` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `bugs` ENABLE KEYS */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

