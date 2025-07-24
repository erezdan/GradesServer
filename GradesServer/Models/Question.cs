namespace GradesServer.Models
{
    public class Question
    {
        public int QuestionId { get; set; }
        public int SnapshotId { get; set; }
        public string QuestionText { get; set; } = string.Empty;
        public int? Score { get; set; }
        public bool IsRelevant { get; set; }

        public int? TestId { get; set; }
        public Test? Test { get; set; }
    }
}
