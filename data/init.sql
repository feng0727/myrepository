CREATE DATABASE /*!32312 IF NOT EXISTS*/`uyundemo` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `uyundemo`;

/*Table structure for table `app_version` */

DROP TABLE IF EXISTS `app_version`;

CREATE TABLE `app_version` (
  `app_version_id` INT(11)      NOT NULL AUTO_INCREMENT,
  `app_name`       VARCHAR(100) NOT NULL
  COMMENT 'app名称',
  `app_version`    VARCHAR(30)  NOT NULL
  COMMENT 'app版本\n',
  `app_type`       TINYINT(4)   NOT NULL
  COMMENT 'app类型\n1 android\n2 ios\n3 wp',
  `app_status`     VARCHAR(45)  NOT NULL
  COMMENT 'app状态\n1 正常\n0 失效',
  `app_path`       VARCHAR(300) NOT NULL,
  `created_at`     DATETIME     NOT NULL,
  `updated_at`      DATETIME     NOT NULL,
  PRIMARY KEY (`app_version_id`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COMMENT = 'app版本管理';

/*Data for the table `app_version` */