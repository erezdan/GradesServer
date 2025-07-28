namespace GradesServer.DTOs
{
    public class StudentReportDto
    {
        public string Title { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public List<ZoneScoreCalculatedDto> Top3Zones { get; set; } = new();
        public List<ZoneScoreCalculatedDto> Bottom3Zones { get; set; } = new();
        public List<ZoneScoreCalculatedDto> Under60Zones { get; set; } = new();
    }
}
