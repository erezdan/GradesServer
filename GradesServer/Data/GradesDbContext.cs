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
            // Subjects
            modelBuilder.Entity<Subject>()
                .HasKey(s => new { s.SnapshotId, s.SubjectId });

            modelBuilder.Entity<Subject>()
                .Property(s => s.SubjectName)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Subject>()
                .Property(s => s.SnapshotId)
                .IsRequired();

            // Zones
            modelBuilder.Entity<Zone>()
                .HasKey(z => new { z.SnapshotId, z.ZoneId });

            modelBuilder.Entity<Zone>()
                .Property(z => z.ZoneName)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Zone>()
                .Property(z => z.SnapshotId)
                .IsRequired();

            // Questions
            modelBuilder.Entity<Question>()
                .HasKey(q => new { q.SnapshotId, q.QuestionId });

            modelBuilder.Entity<Question>()
                .Property(q => q.QuestionText)
                .IsRequired();

            modelBuilder.Entity<Question>()
                .Property(q => q.SnapshotId)
                .IsRequired();

            modelBuilder.Entity<Question>()
                .Property(q => q.Score)
                .HasDefaultValue(null);

            modelBuilder.Entity<Question>()
                .HasOne<Test>()
                .WithMany()
                .HasForeignKey(q => q.TestId)
                .OnDelete(DeleteBehavior.SetNull);

            // Tests
            modelBuilder.Entity<Test>()
                .HasKey(t => t.TestId);

            modelBuilder.Entity<Test>()
                .Property(t => t.TestName)
            .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Test>()
                .Property(t => t.IsATest)
                .IsRequired();

            // SubjectZones (many-to-many)
            modelBuilder.Entity<SubjectZone>()
                .HasKey(sz => new { sz.SnapshotId, sz.SubjectId, sz.ZoneId });

            modelBuilder.Entity<SubjectZone>()
                .HasOne<Subject>()
                .WithMany()
                .HasForeignKey(sz => new { sz.SnapshotId, sz.SubjectId })
                .HasPrincipalKey(s => new { s.SnapshotId, s.SubjectId });

            modelBuilder.Entity<SubjectZone>()
                .HasOne<Zone>()
                .WithMany()
                .HasForeignKey(sz => new { sz.SnapshotId, sz.ZoneId })
                .HasPrincipalKey(z => new { z.SnapshotId, z.ZoneId });

            // ZonesQuestions (many-to-many)
            modelBuilder.Entity<ZoneQuestion>()
                .HasKey(zq => new { zq.SnapshotId, zq.ZoneId, zq.QuestionId });

            modelBuilder.Entity<ZoneQuestion>()
                .HasOne<Zone>()
                .WithMany()
                .HasForeignKey(zq => new { zq.SnapshotId, zq.ZoneId });

            modelBuilder.Entity<ZoneQuestion>()
                .HasOne<Question>()
                .WithMany()
                .HasForeignKey(zq => new { zq.SnapshotId, zq.QuestionId });
        }
    }
}
