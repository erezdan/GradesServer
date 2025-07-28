USE [Grades]
GO
/****** Object:  StoredProcedure [dbo].[simple_migration_script]    Script Date: 28/07/2025 10:23:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[simple_migration_script]
    @SnapshotId INT,
    @NumZones INT,
    @NumQuestionsPerZone INT,
    @SubjectId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ZoneId INT;
    DECLARE @QuestionId INT;
    DECLARE @TestId INT;
    DECLARE @i INT = 1;
    DECLARE @j INT;
    DECLARE @SubjectName NVARCHAR(100);
    DECLARE @ZoneName NVARCHAR(100);
    DECLARE @QuestionText NVARCHAR(200);

    -- Step 1: Create Subject with empty name
    INSERT INTO Subjects (SnapshotId, SubjectName)
    VALUES (@SnapshotId, '');

    SET @SubjectId = SCOPE_IDENTITY();
    SET @SubjectName = 'Subject #' + CAST(@SubjectId AS NVARCHAR);

    UPDATE Subjects
    SET SubjectName = @SubjectName
    WHERE SubjectId = @SubjectId;

    -- Step 2: Create a test
    INSERT INTO Tests (TestName, IsATest)
    VALUES (@SubjectName + ' - Test', 1);  -- Set IsATest=0 if needed

    SET @TestId = SCOPE_IDENTITY();

    -- Step 3: Create Zones and Questions
    WHILE @i <= @NumZones
    BEGIN
        -- Create Zone
        INSERT INTO Zones (SnapshotId, ZoneName, IsRelevant)
        VALUES (@SnapshotId, '', 1);

        SET @ZoneId = SCOPE_IDENTITY();
        SET @ZoneName = @SubjectName + ' - Zone #' + CAST(@ZoneId AS NVARCHAR);

        UPDATE Zones
        SET ZoneName = @ZoneName
        WHERE ZoneId = @ZoneId;

        INSERT INTO SubjectZones (SnapshotId, SubjectId, ZoneId)
        VALUES (@SnapshotId, @SubjectId, @ZoneId);

        SET @j = 1;
        WHILE @j <= @NumQuestionsPerZone
        BEGIN
            -- Create Question
            INSERT INTO Questions (SnapshotId, TestId, QuestionText, Score, IsRelevant)
            VALUES (@SnapshotId, @TestId, '', 0, 1);

            SET @QuestionId = SCOPE_IDENTITY();
            SET @QuestionText = @ZoneName + ' - Question #' + CAST(@QuestionId AS NVARCHAR);

            UPDATE Questions
            SET QuestionText = @QuestionText
            WHERE QuestionId = @QuestionId;

            INSERT INTO ZonesQuestions (SnapshotId, ZoneId, QuestionId)
            VALUES (@SnapshotId, @ZoneId, @QuestionId);

            SET @j += 1;
        END

        SET @i += 1;
    END

    PRINT 'Catalog generated under SnapshotId = ' + CAST(@SnapshotId AS NVARCHAR) +
          ' with SubjectId = ' + CAST(@SubjectId AS NVARCHAR);
END
