-- MySQL dump 10.11
--
-- Host: localhost    Database: tech_watch
-- ------------------------------------------------------
-- Server version	5.0.95

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
-- Table structure for table `fc_projects`
--

DROP TABLE IF EXISTS `fc_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fc_projects` (
  `id` varchar(128) NOT NULL default '',
  `project_url` varchar(128) NOT NULL default '',
  `title` varchar(128) NOT NULL default '',
  `issued` datetime NOT NULL,
  `created` timestamp NULL default NULL on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fc_projects_tags`
--

DROP TABLE IF EXISTS `fc_projects_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fc_projects_tags` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `project_id` varchar(128) NOT NULL default '',
  `tag_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `project_id` (`project_id`,`tag_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2721940 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gh_events`
--

DROP TABLE IF EXISTS `gh_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gh_events` (
  `id` varchar(36) NOT NULL default '',
  `project_id` varchar(36) default NULL,
  `type` varchar(36) default NULL,
  `created` timestamp NULL default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gh_projects`
--

DROP TABLE IF EXISTS `gh_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gh_projects` (
  `id` varchar(36) NOT NULL default '',
  `name` varchar(256) default NULL,
  `updated` datetime default NULL,
  `created` timestamp NULL default NULL on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gh_projects_tags`
--

DROP TABLE IF EXISTS `gh_projects_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gh_projects_tags` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `project_id` varchar(36) NOT NULL default '',
  `tag_id` varchar(36) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `project_id` (`project_id`,`tag_id`)
) ENGINE=MyISAM AUTO_INCREMENT=785124 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `so_questions`
--

DROP TABLE IF EXISTS `so_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `so_questions` (
  `id` varchar(32) NOT NULL default '',
  `title` varchar(256) default NULL,
  `answer_count` int(11) default NULL,
  `creation_date` datetime default NULL,
  `last_activity_date` datetime default NULL,
  `view_count` int(11) default NULL,
  `link` varchar(256) default NULL,
  PRIMARY KEY  (`id`),
  KEY `idx_last_activity` (`last_activity_date`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `so_questions_tags`
--

DROP TABLE IF EXISTS `so_questions_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `so_questions_tags` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `question_id` varchar(32) NOT NULL default '',
  `tag_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `question_id` (`question_id`,`tag_id`)
) ENGINE=MyISAM AUTO_INCREMENT=11005310 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `so_tags`
--

DROP TABLE IF EXISTS `so_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `so_tags` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(256) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=38201 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `technology_metadata`
--

DROP TABLE IF EXISTS `technology_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `technology_metadata` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `technology` varchar(255) default NULL,
  `created` datetime default NULL,
  `updated` timestamp NULL default NULL on update CURRENT_TIMESTAMP,
  `wikipedia_url` varchar(255) default NULL,
  `blurb` text,
  `url` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=23 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary table structure for view `view_fc_top_tags_this_week`
--

DROP TABLE IF EXISTS `view_fc_top_tags_this_week`;
/*!50001 DROP VIEW IF EXISTS `view_fc_top_tags_this_week`*/;
/*!50001 CREATE TABLE `view_fc_top_tags_this_week` (
  `c` bigint(21),
  `tag_id` int(11),
  `name` varchar(256)
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `view_gh_most_active_projects_this_week`
--

DROP TABLE IF EXISTS `view_gh_most_active_projects_this_week`;
/*!50001 DROP VIEW IF EXISTS `view_gh_most_active_projects_this_week`*/;
/*!50001 CREATE TABLE `view_gh_most_active_projects_this_week` (
  `c` bigint(21),
  `name` varchar(256),
  `id` varchar(36)
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `view_gh_most_active_projects_with_tags`
--

DROP TABLE IF EXISTS `view_gh_most_active_projects_with_tags`;
/*!50001 DROP VIEW IF EXISTS `view_gh_most_active_projects_with_tags`*/;
/*!50001 CREATE TABLE `view_gh_most_active_projects_with_tags` (
  `c` bigint(21),
  `project_name` varchar(256),
  `tag_name` varchar(256),
  `tag_id` int(11) unsigned
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `view_so_top_tags`
--

DROP TABLE IF EXISTS `view_so_top_tags`;
/*!50001 DROP VIEW IF EXISTS `view_so_top_tags`*/;
/*!50001 CREATE TABLE `view_so_top_tags` (
  `c` bigint(21),
  `tag_id` int(11),
  `name` varchar(256)
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `view_so_top_tags_this_week`
--

DROP TABLE IF EXISTS `view_so_top_tags_this_week`;
/*!50001 DROP VIEW IF EXISTS `view_so_top_tags_this_week`*/;
/*!50001 CREATE TABLE `view_so_top_tags_this_week` (
  `c` bigint(21),
  `tag_id` int(11),
  `name` varchar(256)
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `view_top_tags_across_all_sources`
--

DROP TABLE IF EXISTS `view_top_tags_across_all_sources`;
/*!50001 DROP VIEW IF EXISTS `view_top_tags_across_all_sources`*/;
/*!50001 CREATE TABLE `view_top_tags_across_all_sources` (
  `c` bigint(21),
  `name` varchar(256)
) ENGINE=MyISAM */;

--
-- Final view structure for view `view_fc_top_tags_this_week`
--

/*!50001 DROP TABLE `view_fc_top_tags_this_week`*/;
/*!50001 DROP VIEW IF EXISTS `view_fc_top_tags_this_week`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`editor`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `view_fc_top_tags_this_week` AS select count(0) AS `c`,`qt`.`tag_id` AS `tag_id`,`t`.`name` AS `name` from ((`fc_projects_tags` `qt` left join `so_tags` `t` on((`qt`.`tag_id` = `t`.`id`))) left join `fc_projects` `q` on((`qt`.`project_id` = `q`.`id`))) where (`q`.`issued` > (now() - interval 1 week)) group by `qt`.`tag_id` order by count(0) desc */;

--
-- Final view structure for view `view_gh_most_active_projects_this_week`
--

/*!50001 DROP TABLE `view_gh_most_active_projects_this_week`*/;
/*!50001 DROP VIEW IF EXISTS `view_gh_most_active_projects_this_week`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`editor`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `view_gh_most_active_projects_this_week` AS select count(0) AS `c`,`p`.`name` AS `name`,`p`.`id` AS `id` from (`gh_events` `e` join `gh_projects` `p`) where ((`e`.`project_id` = `p`.`id`) and (`e`.`created` > (now() - interval 1 week))) group by `e`.`project_id` order by count(0) desc */;

--
-- Final view structure for view `view_gh_most_active_projects_with_tags`
--

/*!50001 DROP TABLE `view_gh_most_active_projects_with_tags`*/;
/*!50001 DROP VIEW IF EXISTS `view_gh_most_active_projects_with_tags`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`editor`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `view_gh_most_active_projects_with_tags` AS select `p`.`c` AS `c`,`p`.`name` AS `project_name`,`t`.`name` AS `tag_name`,`t`.`id` AS `tag_id` from ((`view_gh_most_active_projects_this_week` `p` join `gh_projects_tags` `pt`) join `so_tags` `t`) where ((`p`.`id` = `pt`.`project_id`) and (`pt`.`tag_id` = `t`.`id`)) */;

--
-- Final view structure for view `view_so_top_tags`
--

/*!50001 DROP TABLE `view_so_top_tags`*/;
/*!50001 DROP VIEW IF EXISTS `view_so_top_tags`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`editor`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `view_so_top_tags` AS select count(0) AS `c`,`qt`.`tag_id` AS `tag_id`,`t`.`name` AS `name` from (`so_questions_tags` `qt` left join `so_tags` `t` on((`qt`.`tag_id` = `t`.`id`))) group by `qt`.`tag_id` order by count(0) desc */;

--
-- Final view structure for view `view_so_top_tags_this_week`
--

/*!50001 DROP TABLE `view_so_top_tags_this_week`*/;
/*!50001 DROP VIEW IF EXISTS `view_so_top_tags_this_week`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`editor`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `view_so_top_tags_this_week` AS select count(0) AS `c`,`qt`.`tag_id` AS `tag_id`,`t`.`name` AS `name` from ((`so_questions_tags` `qt` left join `so_tags` `t` on((`qt`.`tag_id` = `t`.`id`))) left join `so_questions` `q` on((`qt`.`question_id` = `q`.`id`))) where (`q`.`creation_date` > (now() - interval 1 week)) group by `qt`.`tag_id` order by count(0) desc */;

--
-- Final view structure for view `view_top_tags_across_all_sources`
--

/*!50001 DROP TABLE `view_top_tags_across_all_sources`*/;
/*!50001 DROP VIEW IF EXISTS `view_top_tags_across_all_sources`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`editor`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `view_top_tags_across_all_sources` AS select count(0) AS `c`,`t1`.`name` AS `name` from ((`fc_projects_tags` `pt` join `so_tags` `t1` on((`pt`.`tag_id` = `t1`.`id`))) join (`so_questions_tags` `qt` join `so_tags` `t2` on((`qt`.`tag_id` = `t2`.`id`)))) where (`pt`.`tag_id` = `qt`.`tag_id`) group by `qt`.`tag_id` order by count(0) desc */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-06-09 20:25:49
