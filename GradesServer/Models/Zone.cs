namespace GradesServer.Models
{
    public class Zone
    {
        public int ZoneId { get; set; }
        public int SnapshotId { get; set; }
        public string ZoneName { get; set; } = string.Empty;
        public bool IsRelevant { get; set; }
    }
}
