-- Project: Bricolage
--
-- $Id$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- -----------------------------------------------------------------------------
-- Member.sql
-- 
--
-- The member table and the tables that map member bac to their respective 
-- objects.   The member table contains an id and a group id.   The table that 
-- maps the object to its member contains an id an object id and a member id
--
-- Thought should be given to:
-- 		Ensuring that an object is not placed with in the same group twice
--		Making sure that an object that is deactivated from a group that is 
--			then put back in again will behave properly
--


-- -----------------------------------------------------------------------------
-- Table: member
--
-- Description:	The table that creates a member of a group.   The obj_member 
-- table then links the objects to the member table
--

CREATE TABLE member (
    id         INTEGER        NOT NULL AUTO_INCREMENT,
    grp__id    INTEGER        NOT NULL,
    class__id  INTEGER        NOT NULL,
    active     BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_member__id PRIMARY KEY (id)
)
    ENGINE     InnoDB
    AUTO_INCREMENT 1024;


--
-- INDEXES.
--
CREATE INDEX fkx_grp__member ON member(grp__id);
CREATE INDEX fkx_grp__class ON member(class__id);

-- Use the below section as an example to create new member tables for
-- other objects.
-- -----------------------------------------------------------------------------
-- Table: story_member
-- 
-- Description: The link between story objects and member objects
--

CREATE TABLE story_member (
    id          INTEGER        NOT NULL AUTO_INCREMENT,
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_story_member__id PRIMARY KEY (id)
)
    ENGINE     InnoDB
    AUTO_INCREMENT 1024;

--
-- INDEXES.
--
CREATE INDEX fkx_story__story_member ON story_member(object_id);
CREATE INDEX fkx_member__story_member ON story_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE member AUTO_INCREMENT 1024;
ALTER TABLE story_member AUTO_INCREMENT 1024;
