namespace GradesServer.DTOs
{
    public class QuestionDto
    {
        public int SnapshotId { get; set; }
        public int? TestId { get; set; }
        public string QuestionText { get; set; } = string.Empty;
        public int? Score { get; set; }
        public bool IsRelevant { get; set; }
    }
}
