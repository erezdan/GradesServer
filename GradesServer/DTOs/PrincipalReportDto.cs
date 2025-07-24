namespace GradesServer.DTOs
{
    public class PrincipalReportDto
    {
        public string Title { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public LowestZoneDto? LowestZone { get; set; }
    }
}
