USE [Grades]
GO
/****** Object:  StoredProcedure [dbo].[calculate_score_per_snapshot]    Script Date: 28/07/2025 11:37:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[calculate_score_per_snapshot]
    @SnapshotId INT,
    @SubjectId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @SnapshotId AS SnapshotId,
        @SubjectId AS SubjectId,
        s.SubjectName,
        z.ZoneId,
        z.ZoneName,

        COUNT(CASE WHEN t.IsATest = 1 THEN q.QuestionId END) AS NumNationalQuestions,
        COUNT(CASE WHEN t.IsATest = 1 AND q.Score IS NOT NULL THEN q.QuestionId END) AS NumNationalAnsweredQuestions,
        AVG(CASE WHEN t.IsATest = 1 THEN CAST(q.Score AS FLOAT) END) AS NationalTestScores,

        COUNT(CASE WHEN t.IsATest = 0 THEN q.QuestionId END) AS NumNonNationalQuestions,
        COUNT(CASE WHEN t.IsATest = 0 AND q.Score IS NOT NULL THEN q.QuestionId END) AS NumNonNationalAnsweredQuestions,
        AVG(CASE WHEN t.IsATest = 0 THEN CAST(q.Score AS FLOAT) END) AS NonNationalTestScores

    FROM Subjects s
    INNER JOIN SubjectZones sz ON sz.SubjectId = s.SubjectId AND sz.SnapshotId = @SnapshotId
    INNER JOIN Zones z ON z.ZoneId = sz.ZoneId AND z.SnapshotId = @SnapshotId
    INNER JOIN ZonesQuestions zq ON zq.ZoneId = z.ZoneId AND zq.SnapshotId = @SnapshotId
    INNER JOIN Questions q ON q.QuestionId = zq.QuestionId AND q.SnapshotId = @SnapshotId
    INNER JOIN Tests t ON t.TestId = q.TestId

    WHERE s.SnapshotId = @SnapshotId AND s.SubjectId = @SubjectId

    GROUP BY s.SubjectName, z.ZoneId, z.ZoneName
    ORDER BY z.ZoneId;
END
