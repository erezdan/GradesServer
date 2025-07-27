using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace GradesServer.Models
{
    [Table("Tests")]
    [PrimaryKey(nameof(TestId))]
    public class Test
    {
        public int TestId { get; set; }

        [Required]
        public string TestName { get; set; } = string.Empty;

        public bool IsATest { get; set; }
    }
}
