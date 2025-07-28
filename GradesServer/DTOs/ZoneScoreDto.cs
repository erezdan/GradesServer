namespace GradesServer.DTOs
{
    public class ZoneScoreDto
    {
        public int SnapshotId { get; set; }
        public int SubjectId { get; set; }
        public string SubjectName { get; set; } = string.Empty;
        public int ZoneId { get; set; }
        public string ZoneName { get; set; } = string.Empty;
        public int NumNationalQuestions { get; set; }
        public int NumNationalAnsweredQuestions { get; set; }
        public double? NationalTestScores { get; set; }
        public int NumNonNationalQuestions { get; set; }
        public int NumNonNationalAnsweredQuestions { get; set; }
        public double? NonNationalTestScores { get; set; }
    }
}
