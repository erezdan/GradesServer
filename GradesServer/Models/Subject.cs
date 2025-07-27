using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace GradesServer.Models
{
    [Table("Subjects")]
    [PrimaryKey(nameof(SubjectId), nameof(SnapshotId))]
    public class Subject
    {
        public int SubjectId { get; set; }

        public int SnapshotId { get; set; }

        [Required]
        public string SubjectName { get; set; } = string.Empty;
    }
}
