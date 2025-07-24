namespace GradesServer.DTOs
{
    public class LowestZoneDto
    {
        public int ZoneId { get; set; }
        public string ZoneName { get; set; } = string.Empty;
        public double AverageScore { get; set; }
    }
}
