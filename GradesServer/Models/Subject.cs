namespace GradesServer.Models
{
    public class Subject
    {
        public int SubjectId { get; set; }
        public int SnapshotId { get; set; }
        public string SubjectName { get; set; } = string.Empty;
    }
}
