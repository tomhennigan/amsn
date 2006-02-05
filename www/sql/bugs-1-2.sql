ALTER TABLE `bugreports` ADD `bug_msnprotocol` INT( 4 ) NOT NULL ;
CREATE TABLE `bugs` (
 `bug_id` INT( 20 ) NOT NULL ,
 `bug_developer` CHAR( 50 ) NOT NULL ,
 `bug_priority` INT( 1 ) NOT NULL ,
 `bug_flag` INT( 2 ) NOT NULL ,
 `bug_error_regexp` TEXT NOT NULL ,
 `bug_stack_regexp` TEXT NOT NULL ,
  PRIMARY KEY ( `bug_id` ) 
) TYPE = MYISAM ;
ALTER TABLE `bugreports` DROP `bug_flag` ;
ALTER TABLE `bugs` ADD `bug_name` VARCHAR( 50 ) NOT NULL DEFAULT 'New Bug' AFTER `bug_id` ;       
ALTER TABLE `bugs` CHANGE `bug_id` `bug_id` INT( 20 ) NOT NULL AUTO_INCREMENT;
DROP TABLE `duplicates` ;
ALTER TABLE `bugs` ADD `bug_desc` TEXT NOT NULL ;
ALTER TABLE `bugs` CHANGE `bug_developer` `bug_developer` CHAR( 50 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'Nobody';
ALTER TABLE `bugs` ADD `bug_last_update` INT( 20 ) NOT NULL AFTER `bug_priority` ;
DROP TABLE flags;
ALTER TABLE `bugreports` ADD `bug_parent` INT( 20 ) NOT NULL ;
