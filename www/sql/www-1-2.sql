CREATE TABLE `amsn_langs` (
 `lang_id` INT( 20 ) NOT NULL AUTO_INCREMENT PRIMARY KEY ,
 `lang_code` CHAR( 5 ) NOT NULL ,
 `lang_key` CHAR( 20 ) NOT NULL ,
 `lang_text` TEXT NOT NULL 
) TYPE = MYISAM ;
ALTER TABLE `amsn_langs` CHANGE `lang_code` `lang_code` CHAR( 5 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'en'
