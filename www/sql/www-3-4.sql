CREATE TABLE `amsn_plugins` (
  `id` int(10) NOT NULL auto_increment,
  `name` varchar(100) NOT NULL default '',
  `desc` varchar(255) NOT NULL default '',
  `author` varchar(100) NOT NULL default '',
  `version` varchar(20) NOT NULL default '',
  `platform` varchar(50) NOT NULL default '',
  `requires` varchar(50) NOT NULL default '',
  `screen` int(11) NOT NULL default '0',
  `url` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `amsn_skins` (
  `id` int(10) NOT NULL auto_increment,
  `name` varchar(100) NOT NULL default '',
  `desc` varchar(255) NOT NULL default '',
  `author` varchar(100) NOT NULL default '',
  `screen` int(11) NOT NULL default '0',
  `url` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
