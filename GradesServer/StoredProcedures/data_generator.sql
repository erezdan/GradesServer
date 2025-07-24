USE [Grades]
GO
/****** Object:  StoredProcedure [dbo].[data_generator]    Script Date: 24/07/2025 18:23:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[data_generator]
    @NumSubjects INT,
    @NumZonesPerSubject INT,
    @NumQuestionsPerZone INT,
    @NumTests INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @i INT = 1;
    WHILE @i <= @NumSubjects
    BEGIN
        DECLARE @OriginalSubjectId INT;

        -- Step 1: Create initial subject in snapshot 0
        EXEC simple_migration_script
            @SnapshotId = 0,
            @NumZones = @NumZonesPerSubject,
            @NumQuestionsPerZone = @NumQuestionsPerZone,
            @NumTests = @NumTests,
            @SubjectId = @OriginalSubjectId OUTPUT;

        -- Step 2: Create new snapshot
        DECLARE @NewSnapshotId INT;
        SELECT @NewSnapshotId = ISNULL(MAX(SnapshotId), 0) + 1 FROM Subjects;

        -- Step 3: Clone subject
        DECLARE @SubjectName NVARCHAR(100);
        SELECT @SubjectName = SubjectName FROM Subjects WHERE SubjectId = @OriginalSubjectId AND SnapshotId = 0;

        INSERT INTO Subjects (SnapshotId, SubjectName)
        VALUES (@NewSnapshotId, @SubjectName);

        DECLARE @NewSubjectId INT = SCOPE_IDENTITY();

        --------------------------------------
        -- Step 4: Clone Tests FIRST (before Questions)
        --------------------------------------
        DECLARE @TestMap TABLE (OldTestId INT, NewTestId INT);
        DECLARE @OldTestId INT;
        DECLARE TestCursor CURSOR FOR
        SELECT DISTINCT q.TestId
        FROM Questions q
        JOIN ZonesQuestions zq ON q.QuestionId = zq.QuestionId
        JOIN SubjectZones sz ON zq.ZoneId = sz.ZoneId
        WHERE sz.SubjectId = @OriginalSubjectId 
          AND q.SnapshotId = 0 
          AND q.TestId IS NOT NULL;

        OPEN TestCursor;
        FETCH NEXT FROM TestCursor INTO @OldTestId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @TestName NVARCHAR(100);
            DECLARE @IsATest BIT;

            SELECT @TestName = TestName, @IsATest = IsATest FROM Tests WHERE TestId = @OldTestId;

            INSERT INTO Tests (TestName, IsATest)
            VALUES (@TestName, @IsATest);

            DECLARE @NewTestId INT = SCOPE_IDENTITY();
            INSERT INTO @TestMap (OldTestId, NewTestId) VALUES (@OldTestId, @NewTestId);

            FETCH NEXT FROM TestCursor INTO @OldTestId;
        END

        CLOSE TestCursor;
        DEALLOCATE TestCursor;

        --------------------------------------
        -- Step 5: Clone Zones
        --------------------------------------
        DECLARE @ZoneMap TABLE (OldZoneId INT, NewZoneId INT);
        DECLARE @ZoneData TABLE (OldZoneId INT, ZoneName NVARCHAR(100), IsRelevant BIT);

        INSERT INTO @ZoneData (OldZoneId, ZoneName, IsRelevant)
        SELECT z.ZoneId, z.ZoneName, z.IsRelevant
        FROM Zones z
        JOIN SubjectZones sz ON z.ZoneId = sz.ZoneId AND sz.SnapshotId = 0
        WHERE sz.SubjectId = @OriginalSubjectId AND z.SnapshotId = 0;

        DECLARE @OldZoneId INT, @ZoneName NVARCHAR(100), @IsRelevant BIT;
        DECLARE ZoneCursor CURSOR FOR SELECT OldZoneId, ZoneName, IsRelevant FROM @ZoneData;

        OPEN ZoneCursor;
        FETCH NEXT FROM ZoneCursor INTO @OldZoneId, @ZoneName, @IsRelevant;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO Zones (SnapshotId, ZoneName, IsRelevant)
            VALUES (@NewSnapshotId, @ZoneName, @IsRelevant);

            DECLARE @NewZoneId INT = SCOPE_IDENTITY();
            INSERT INTO @ZoneMap (OldZoneId, NewZoneId) VALUES (@OldZoneId, @NewZoneId);

            FETCH NEXT FROM ZoneCursor INTO @OldZoneId, @ZoneName, @IsRelevant;
        END

        CLOSE ZoneCursor;
        DEALLOCATE ZoneCursor;

        --------------------------------------
        -- Step 6: Clone SubjectZones (only if zones exist in Zones table)
        --------------------------------------
        INSERT INTO SubjectZones (SnapshotId, SubjectId, ZoneId)
        SELECT @NewSnapshotId, @NewSubjectId, zm.NewZoneId
        FROM @ZoneMap zm
        WHERE EXISTS (
            SELECT 1 FROM Zones z WHERE z.ZoneId = zm.NewZoneId AND z.SnapshotId = @NewSnapshotId
        );

        --------------------------------------
        -- Step 7: Clone Questions with mapped TestId
        --------------------------------------
        DECLARE @QuestionMap TABLE (OldQuestionId INT, NewQuestionId INT);        
        DECLARE @QuestionData TABLE (
            OldQuestionId INT, 
            TestId INT, 
            QuestionText NVARCHAR(MAX), 
            Score INT,
            IsRelevant BIT
        );

        INSERT INTO @QuestionData (OldQuestionId, TestId, QuestionText, Score, IsRelevant)
        SELECT
            q.QuestionId,
            COALESCE(tm.NewTestId, q.TestId),
            q.QuestionText,
            q.Score,
            q.IsRelevant
        FROM Questions q
        JOIN ZonesQuestions zq ON q.QuestionId = zq.QuestionId
        JOIN @ZoneMap zm ON zq.ZoneId = zm.OldZoneId
        LEFT JOIN @TestMap tm ON q.TestId = tm.OldTestId
        WHERE q.SnapshotId = 0;

        DECLARE @OldQuestionId INT, @TestId INT, @QuestionText NVARCHAR(MAX), @Score INT, @QuestionIsRelevant BIT;
        DECLARE QuestionCursor CURSOR FOR
        SELECT OldQuestionId, TestId, QuestionText, Score, IsRelevant FROM @QuestionData;

        OPEN QuestionCursor;
        FETCH NEXT FROM QuestionCursor INTO @OldQuestionId, @TestId, @QuestionText, @Score, @QuestionIsRelevant;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO Questions (SnapshotId, TestId, QuestionText, Score, IsRelevant)
            VALUES (@NewSnapshotId, @TestId, @QuestionText, @Score, @QuestionIsRelevant);

            DECLARE @NewQuestionId INT = SCOPE_IDENTITY();
            INSERT INTO @QuestionMap (OldQuestionId, NewQuestionId) VALUES (@OldQuestionId, @NewQuestionId);

            FETCH NEXT FROM QuestionCursor INTO @OldQuestionId, @TestId, @QuestionText, @Score, @QuestionIsRelevant;
        END

        CLOSE QuestionCursor;
        DEALLOCATE QuestionCursor;

        --------------------------------------
        -- Step 8: Clone ZonesQuestions (only if zones and questions exist)
        --------------------------------------
        INSERT INTO ZonesQuestions (SnapshotId, ZoneId, QuestionId)
        SELECT @NewSnapshotId, zm.NewZoneId, qm.NewQuestionId
        FROM ZonesQuestions zq
        JOIN @ZoneMap zm ON zq.ZoneId = zm.OldZoneId
        JOIN @QuestionMap qm ON zq.QuestionId = qm.OldQuestionId
        WHERE zq.SnapshotId = 0
        AND EXISTS (
            SELECT 1 FROM Zones z WHERE z.ZoneId = zm.NewZoneId AND z.SnapshotId = @NewSnapshotId
        )
        AND EXISTS (
            SELECT 1 FROM Questions q WHERE q.QuestionId = qm.NewQuestionId AND q.SnapshotId = @NewSnapshotId
        );

        SET @i += 1;
    END
END
