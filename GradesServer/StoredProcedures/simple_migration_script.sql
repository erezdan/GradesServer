USE [Grades]
GO
/****** Object:  StoredProcedure [dbo].[simple_migration_script]    Script Date: 24/07/2025 18:23:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[simple_migration_script]
    @SnapshotId INT,
    @NumZones INT,
    @NumQuestionsPerZone INT,
    @NumTests INT,
    @SubjectId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ZoneId INT;
    DECLARE @QuestionId INT;
    DECLARE @TestId INT;
    DECLARE @i INT;
    DECLARE @j INT;
    DECLARE @k INT;

    DECLARE @ZoneNumber INT;
    DECLARE @QuestionNumber INT;
    DECLARE @TestNumber INT;

    -- Insert subject with temporary name, get actual ID and update name
    INSERT INTO Subjects (SnapshotId, SubjectName)
    VALUES (@SnapshotId, '');

    SET @SubjectId = SCOPE_IDENTITY();
    DECLARE @SubjectName NVARCHAR(100) = 'Subject #' + CAST(@SubjectId AS NVARCHAR);

    UPDATE Subjects
    SET SubjectName = @SubjectName
    WHERE SubjectId = @SubjectId;

    -- Store created tests in memory
    DECLARE @Tests TABLE (TestId INT);

    -- Create tests with names based on real subject ID
    SET @k = 1;
    WHILE @k <= @NumTests
    BEGIN
        SET @TestNumber = @k;
        DECLARE @TestName NVARCHAR(100) = @SubjectName + ' - Test #' + CAST(@TestNumber AS NVARCHAR);
        DECLARE @IsATest BIT = IIF(@k % 2 = 0, 1, 0); -- Alternate between A-test and non-A-test

        INSERT INTO Tests (TestName, IsATest)
        VALUES (@TestName, @IsATest);

        SET @TestId = SCOPE_IDENTITY();
        INSERT INTO @Tests (TestId) VALUES (@TestId);

        SET @k += 1;
    END

    -- Create zones and questions with names based on real IDs
    SET @i = 1;
    WHILE @i <= @NumZones
    BEGIN
        SET @ZoneNumber = @i;

        -- Insert zone with temporary name
        INSERT INTO Zones (SnapshotId, ZoneName, IsRelevant)
        VALUES (@SnapshotId, '', 1);

        SET @ZoneId = SCOPE_IDENTITY();
        DECLARE @ZoneName NVARCHAR(100) = @SubjectName + ' - Zone #' + CAST(@ZoneId AS NVARCHAR);

        -- Update zone name
        UPDATE Zones
        SET ZoneName = @ZoneName
        WHERE ZoneId = @ZoneId;

        INSERT INTO SubjectZones (SnapshotId, SubjectId, ZoneId)
        VALUES (@SnapshotId, @SubjectId, @ZoneId);

        SET @j = 1;
        WHILE @j <= @NumQuestionsPerZone
        BEGIN
            SET @QuestionNumber = @j;

            -- Pick a random test for the question
            SELECT TOP 1 @TestId = TestId FROM @Tests ORDER BY NEWID();

            -- Insert question with temporary text
            INSERT INTO Questions (SnapshotId, TestId, QuestionText, Score, IsRelevant)
            VALUES (@SnapshotId, @TestId, '', 0, 1);

            SET @QuestionId = SCOPE_IDENTITY();

            DECLARE @QuestionText NVARCHAR(200) =
                @SubjectName + ' - Zone #' + CAST(@ZoneId AS NVARCHAR) + ' - Question #' + CAST(@QuestionId AS NVARCHAR);

            -- Update question text
            UPDATE Questions
            SET QuestionText = @QuestionText
            WHERE QuestionId = @QuestionId;

            INSERT INTO ZonesQuestions (SnapshotId, ZoneId, QuestionId)
            VALUES (@SnapshotId, @ZoneId, @QuestionId);

            SET @j += 1;
        END

        SET @i += 1;
    END

    PRINT 'Catalog generated under SnapshotId = ' + CAST(@SnapshotId AS NVARCHAR)
          + ' with SubjectId = ' + CAST(@SubjectId AS NVARCHAR);
END
