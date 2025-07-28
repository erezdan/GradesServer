using GradesServer.DTOs;
using GradesServer.Models;
using Microsoft.EntityFrameworkCore;
using static System.Net.Mime.MediaTypeNames;

namespace GradesServer.Data
{
    public class GradesDbContext : DbContext
    {
        public GradesDbContext(DbContextOptions<GradesDbContext> options)
            : base(options)
        {
        }

        public DbSet<Subject> Subjects { get; set; }
        public DbSet<Zone> Zones { get; set; }
        public DbSet<Question> Questions { get; set; }
        public DbSet<Test> Tests { get; set; }
        public DbSet<SubjectZone> SubjectZones { get; set; }
        public DbSet<ZoneQuestion> ZonesQuestions { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<SnapshotScoreDto>().HasNoKey();
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<ZoneScoreDto>().HasNoKey();
            base.OnModelCreating(modelBuilder);
        }
    }
}
