using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace GradesServer.Models
{
    [Table("SubjectZones")]
    [PrimaryKey(nameof(SubjectId), nameof(ZoneId), nameof(SnapshotId))]
    public class SubjectZone
    {
        public int SubjectId { get; set; }

        public int ZoneId { get; set; }

        public int SnapshotId { get; set; }
    }
}
