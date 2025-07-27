using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace GradesServer.Models
{
    [Table("ZonesQuestions")]
    [PrimaryKey(nameof(ZoneId), nameof(QuestionId), nameof(SnapshotId))]
    public class ZoneQuestion
    {
        public int ZoneId { get; set; }

        public int QuestionId { get; set; }

        public int SnapshotId { get; set; }
    }
}
