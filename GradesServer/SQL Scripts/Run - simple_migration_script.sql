DECLARE @SubjectId INT;

EXEC simple_migration_script
    @SnapshotId = 0,
    @NumZones = 3,
    @NumQuestionsPerZone = 5,
    @SubjectId = @SubjectId OUTPUT;

SELECT @SubjectId AS CreatedSubjectId;
