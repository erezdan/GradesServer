using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace GradesServer.Models
{
    [Table("Questions")]
    [PrimaryKey(nameof(QuestionId), nameof(SnapshotId))]
    public class Question
    {
        [JsonIgnore]
        public int QuestionId { get; set; }

        public int SnapshotId { get; set; }

        [Required]
        public string QuestionText { get; set; } = string.Empty;

        public int? Score { get; set; }

        public bool IsRelevant { get; set; }

        [ForeignKey("Test")]
        public int TestId { get; set; }
    }
}
