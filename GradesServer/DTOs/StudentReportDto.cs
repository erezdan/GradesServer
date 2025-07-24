namespace GradesServer.DTOs
{
    public class StudentReportDto
    {
        public string Title { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public List<ZoneScoreDto> Top3Zones { get; set; } = new();
        public List<ZoneScoreDto> Bottom3Zones { get; set; } = new();
        public List<ZoneScoreDto> Under60Zones { get; set; } = new();
    }
}
