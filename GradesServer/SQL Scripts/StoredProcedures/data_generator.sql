ALTER PROCEDURE [dbo].[data_generator]
    @NumSubjects INT,
    @NumZonesPerSubject INT,
    @NumQuestionsPerZone INT,
    @NumTests INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Step 1: Create new snapshot
    DECLARE @NewSnapshotId INT;
    SELECT @NewSnapshotId = ISNULL(MAX(SnapshotId), 0) + 1 FROM Subjects;

    -- Step 2: First create all subjects in snapshot 0 using simple_migration_script
    DECLARE @OriginalSubjectIds TABLE (SubjectId INT);
    DECLARE @i INT = 1;

    WHILE @i <= @NumSubjects
    BEGIN
        DECLARE @OriginalSubjectId INT;

        EXEC simple_migration_script
            @SnapshotId = 0,
            @NumZones = @NumZonesPerSubject,
            @NumQuestionsPerZone = @NumQuestionsPerZone,
            @SubjectId = @OriginalSubjectId OUTPUT;

        IF @OriginalSubjectId IS NULL
        BEGIN
            RAISERROR('simple_migration_script failed to return a valid SubjectId', 16, 1);
            RETURN;
        END

        INSERT INTO @OriginalSubjectIds (SubjectId) VALUES (@OriginalSubjectId);
        SET @i += 1;
    END

    -- Step 3: Create new tests and initialize stats table
    DECLARE @Tests TABLE (RowNum INT IDENTITY(1,1), TestId INT);
    DECLARE @TestStats TABLE (TestId INT PRIMARY KEY, QuestionCount INT DEFAULT 0);

    DECLARE @t INT = 1;
    WHILE @t <= @NumTests
    BEGIN
        DECLARE @TestName NVARCHAR(100) = 'Generated Test ' + CAST(@t AS NVARCHAR);
        
        INSERT INTO Tests (TestName, IsATest)
        VALUES (@TestName, 1);

        DECLARE @NewTestId INT = SCOPE_IDENTITY();
        INSERT INTO @Tests (TestId) VALUES (@NewTestId);
        INSERT INTO @TestStats (TestId) VALUES (@NewTestId);

        SET @t += 1;
    END

    -- Step 4: Clone catalog data from snapshot 0 to new snapshot

    -- Clone all Zones
    DECLARE @ZoneMap TABLE (OldZoneId INT, NewZoneId INT);
    DECLARE @OldZoneId INT, @ZoneName NVARCHAR(100), @IsRelevant BIT;
    DECLARE ZoneCursor CURSOR FOR 
    SELECT DISTINCT ZoneId, ZoneName, IsRelevant 
    FROM Zones 
    WHERE SnapshotId = 0;

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

    -- Clone all Questions and assign each to the test with the least questions so far
    DECLARE @QuestionMap TABLE (OldQuestionId INT, NewQuestionId INT);
    DECLARE @OldQuestionId INT, @QuestionText NVARCHAR(MAX), @QuestionIsRelevant BIT;
    DECLARE QuestionCursor CURSOR FOR
    SELECT DISTINCT QuestionId, QuestionText, IsRelevant 
    FROM Questions 
    WHERE SnapshotId = 0;

    OPEN QuestionCursor;
    FETCH NEXT FROM QuestionCursor INTO @OldQuestionId, @QuestionText, @QuestionIsRelevant;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Score INT = NULL;
        IF @QuestionIsRelevant = 1
            SET @Score = CAST(RAND(CHECKSUM(NEWID())) * 100 AS INT);

        DECLARE @TargetTestId INT;
        SELECT TOP 1 @TargetTestId = TestId
        FROM @TestStats
        ORDER BY QuestionCount ASC;

        INSERT INTO Questions (SnapshotId, TestId, QuestionText, Score, IsRelevant)
        VALUES (@NewSnapshotId, @TargetTestId, @QuestionText, @Score, @QuestionIsRelevant);

        UPDATE @TestStats
        SET QuestionCount = QuestionCount + 1
        WHERE TestId = @TargetTestId;

        DECLARE @NewQuestionId INT = SCOPE_IDENTITY();
        INSERT INTO @QuestionMap (OldQuestionId, NewQuestionId) VALUES (@OldQuestionId, @NewQuestionId);

        FETCH NEXT FROM QuestionCursor INTO @OldQuestionId, @QuestionText, @QuestionIsRelevant;
    END

    CLOSE QuestionCursor;
    DEALLOCATE QuestionCursor;

    -- Clone ZonesQuestions relationships
    INSERT INTO ZonesQuestions (SnapshotId, ZoneId, QuestionId)
    SELECT DISTINCT @NewSnapshotId, zm.NewZoneId, qm.NewQuestionId
    FROM ZonesQuestions zq
    JOIN @ZoneMap zm ON zq.ZoneId = zm.OldZoneId
    JOIN @QuestionMap qm ON zq.QuestionId = qm.OldQuestionId
    WHERE zq.SnapshotId = 0;

    -- Step 5: Clone Subjects to new snapshot
    DECLARE @SubjectMap TABLE (OldSubjectId INT, NewSubjectId INT);
    DECLARE SubjectCursor CURSOR FOR 
    SELECT SubjectId FROM @OriginalSubjectIds;

    OPEN SubjectCursor;
    FETCH NEXT FROM SubjectCursor INTO @OriginalSubjectId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @SubjectName NVARCHAR(100);
        SELECT @SubjectName = SubjectName 
        FROM Subjects 
        WHERE SubjectId = @OriginalSubjectId AND SnapshotId = 0;

        IF @SubjectName IS NULL
        BEGIN
            SET @SubjectName = 'Generated Subject ' + CAST(@OriginalSubjectId AS NVARCHAR(10));
        END

        INSERT INTO Subjects (SnapshotId, SubjectName)
        VALUES (@NewSnapshotId, @SubjectName);

        DECLARE @NewSubjectId INT = SCOPE_IDENTITY();
        INSERT INTO @SubjectMap (OldSubjectId, NewSubjectId) VALUES (@OriginalSubjectId, @NewSubjectId);

        FETCH NEXT FROM SubjectCursor INTO @OriginalSubjectId;
    END

    CLOSE SubjectCursor;
    DEALLOCATE SubjectCursor;

    -- Step 6: Clone SubjectZones relationships
    INSERT INTO SubjectZones (SnapshotId, SubjectId, ZoneId)
    SELECT @NewSnapshotId, sm.NewSubjectId, zm.NewZoneId
    FROM SubjectZones sz
    JOIN @SubjectMap sm ON sz.SubjectId = sm.OldSubjectId
    JOIN @ZoneMap zm ON sz.ZoneId = zm.OldZoneId
    WHERE sz.SnapshotId = 0;
END
