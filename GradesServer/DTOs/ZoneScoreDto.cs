namespace GradesServer.DTOs
{
    public class ZoneScoreDto
    {
        public int ZoneId { get; set; }
        public string ZoneName { get; set; } = string.Empty;
        public double Score { get; set; }
    }
}
