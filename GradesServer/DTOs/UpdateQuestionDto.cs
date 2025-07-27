namespace GradesServer.DTOs
{
    public class UpdateQuestionDto
    {
        public string QuestionText { get; set; } = string.Empty;
        public int? Score { get; set; }
        public bool IsRelevant { get; set; }
    }
}
