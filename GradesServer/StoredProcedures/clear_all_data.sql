USE [Grades]
GO
/****** Object:  StoredProcedure [dbo].[clear_all_data]    Script Date: 24/07/2025 18:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[clear_all_data]
AS
BEGIN
    SET NOCOUNT ON;

    -- Disable all foreign key constraints temporarily
    ALTER TABLE ZonesQuestions NOCHECK CONSTRAINT ALL;
    ALTER TABLE SubjectZones NOCHECK CONSTRAINT ALL;
    ALTER TABLE Questions NOCHECK CONSTRAINT ALL;
    ALTER TABLE Zones NOCHECK CONSTRAINT ALL;
    ALTER TABLE Subjects NOCHECK CONSTRAINT ALL;
    ALTER TABLE Tests NOCHECK CONSTRAINT ALL;

    -- Delete in the correct dependency order (child to parent)
    DELETE FROM ZonesQuestions;
    DELETE FROM SubjectZones;
    DELETE FROM Questions;
    DELETE FROM Tests;
    DELETE FROM Zones;
    DELETE FROM Subjects;

    -- Reset identities
    DBCC CHECKIDENT ('Subjects', RESEED, 999);
    DBCC CHECKIDENT ('Zones', RESEED, 1999);
    DBCC CHECKIDENT ('Tests', RESEED, 49999);
    DBCC CHECKIDENT ('Questions', RESEED, 99999);

    -- Re-enable constraints
    ALTER TABLE ZonesQuestions CHECK CONSTRAINT ALL;
    ALTER TABLE SubjectZones CHECK CONSTRAINT ALL;
    ALTER TABLE Questions CHECK CONSTRAINT ALL;
    ALTER TABLE Zones CHECK CONSTRAINT ALL;
    ALTER TABLE Subjects CHECK CONSTRAINT ALL;
    ALTER TABLE Tests CHECK CONSTRAINT ALL;

    PRINT 'All data cleared and identity columns reset.';

    SELECT 
    (SELECT COUNT(*) FROM Subjects) AS SubjectsCount,
    (SELECT COUNT(*) FROM Zones) AS ZonesCount,
    (SELECT COUNT(*) FROM Tests) AS TestsCount,
    (SELECT COUNT(*) FROM Questions) AS QuestionsCount,
    (SELECT COUNT(*) FROM SubjectZones) AS SubjectZonesCount,
    (SELECT COUNT(*) FROM ZonesQuestions) AS ZonesQuestionsCount;
END
