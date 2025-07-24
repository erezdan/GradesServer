namespace GradesServer.Models
{
    public class Test
    {
        public int TestId { get; set; }
        public string TestName { get; set; } = string.Empty;
        public bool IsATest { get; set; }

        public ICollection<Question>? Questions { get; set; }
    }
}
