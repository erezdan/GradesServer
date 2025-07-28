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

        -- Create initial subject in snapshot 0
        EXEC simple_migration_script
            @SnapshotId = 0,
            @NumZones = @NumZonesPerSubject,
            @NumQuestionsPerZone = @NumQuestionsPerZone,
            @SubjectId = @OriginalSubjectId OUTPUT;

        -- Add error handling for the procedure call
        IF @OriginalSubjectId IS NULL
        BEGIN
            RAISERROR('simple_migration_script failed to return a valid SubjectId', 16, 1);
            RETURN;
        END

        INSERT INTO @OriginalSubjectIds (SubjectId) VALUES (@OriginalSubjectId);
        SET @i += 1;
    END

    -- Step 3: Now clone ALL catalog data from snapshot 0 to new snapshot

    -- Clone Tests (Tests table doesn't have SnapshotId, but we need to map for Questions)
    DECLARE @TestMap TABLE (OldTestId INT, NewTestId INT);
    INSERT INTO @TestMap (OldTestId, NewTestId)
    SELECT TestId, TestId FROM Tests; -- Tests don't get duplicated, just mapped

    -- Clone ALL Zones from snapshot 0 to new snapshot
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

    -- Clone ALL Questions from snapshot 0 to new snapshot
    DECLARE @QuestionMap TABLE (OldQuestionId INT, NewQuestionId INT);
    DECLARE @OldQuestionId INT, @TestId INT, @QuestionText NVARCHAR(MAX), @QuestionIsRelevant BIT;
    DECLARE QuestionCursor CURSOR FOR
    SELECT DISTINCT QuestionId, TestId, QuestionText, IsRelevant 
    FROM Questions 
    WHERE SnapshotId = 0;

    OPEN QuestionCursor;
    FETCH NEXT FROM QuestionCursor INTO @OldQuestionId, @TestId, @QuestionText, @QuestionIsRelevant;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Score INT = NULL;
        IF @QuestionIsRelevant = 1
            SET @Score = CAST(RAND(CHECKSUM(NEWID())) * 100 AS INT);

        INSERT INTO Questions (SnapshotId, TestId, QuestionText, Score, IsRelevant)
        VALUES (@NewSnapshotId, @TestId, @QuestionText, @Score, @QuestionIsRelevant);

        DECLARE @NewQuestionId INT = SCOPE_IDENTITY();
        INSERT INTO @QuestionMap (OldQuestionId, NewQuestionId) VALUES (@OldQuestionId, @NewQuestionId);

        FETCH NEXT FROM QuestionCursor INTO @OldQuestionId, @TestId, @QuestionText, @QuestionIsRelevant;
    END

    CLOSE QuestionCursor;
    DEALLOCATE QuestionCursor;

    -- Clone ALL ZonesQuestions relationships
    INSERT INTO ZonesQuestions (SnapshotId, ZoneId, QuestionId)
    SELECT DISTINCT @NewSnapshotId, zm.NewZoneId, qm.NewQuestionId
    FROM ZonesQuestions zq
    JOIN @ZoneMap zm ON zq.ZoneId = zm.OldZoneId
    JOIN @QuestionMap qm ON zq.QuestionId = qm.OldQuestionId
    WHERE zq.SnapshotId = 0;

    -- Step 4: Clone subjects from snapshot 0 to new snapshot
    DECLARE @SubjectMap TABLE (OldSubjectId INT, NewSubjectId INT);
    DECLARE SubjectCursor CURSOR FOR 
    SELECT SubjectId FROM @OriginalSubjectIds;

    OPEN SubjectCursor;
    FETCH NEXT FROM SubjectCursor INTO @OriginalSubjectId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Clone subject
        DECLARE @SubjectName NVARCHAR(100);
        SELECT @SubjectName = SubjectName 
        FROM Subjects 
        WHERE SubjectId = @OriginalSubjectId AND SnapshotId = 0;

        -- Add validation for SubjectName
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

    -- Step 5: Clone SubjectZones relationships
    INSERT INTO SubjectZones (SnapshotId, SubjectId, ZoneId)
    SELECT @NewSnapshotId, sm.NewSubjectId, zm.NewZoneId
    FROM SubjectZones sz
    JOIN @SubjectMap sm ON sz.SubjectId = sm.OldSubjectId
    JOIN @ZoneMap zm ON sz.ZoneId = zm.OldZoneId
    WHERE sz.SnapshotId = 0;

END