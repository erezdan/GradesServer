using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace GradesServer.Models
{
    [Table("Zones")]
    [PrimaryKey(nameof(ZoneId), nameof(SnapshotId))]
    public class Zone
    {
        public int ZoneId { get; set; }

        public int SnapshotId { get; set; }

        [Required]
        public string ZoneName { get; set; } = string.Empty;

        public bool IsRelevant { get; set; }
    }
}
