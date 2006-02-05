CREATE TABLE `_email` (
 `email_id` INT( 20 ) NOT NULL AUTO_INCREMENT PRIMARY KEY ,
 `email_to` CHAR( 50 ) NOT NULL ,
 `email_subject` VARCHAR( 100 ) NOT NULL ,
 `email_body` TEXT NOT NULL 
) TYPE = MYISAM ;
