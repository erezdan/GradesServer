namespace GradesServer.DTOs
{
    public class ReturnedQuestionDto
    {
        public int QuestionId { get; set; }
        public string QuestionText { get; set; } = string.Empty;
        public int? Score { get; set; }
        public bool IsRelevant { get; set; }
    }
}
