-- MySQL dump 10.10
--
-- Host: localhost    Database: www
-- ------------------------------------------------------
-- Server version	5.0.18-log

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
-- Table structure for table `amsn_poll_votes`
--

DROP TABLE IF EXISTS `amsn_poll_votes`;
CREATE TABLE `amsn_poll_votes` (
  `ip` varchar(100) NOT NULL default '',
  `time` int(10) NOT NULL default '0',
  `poll_id` int(10) NOT NULL default '0'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

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
