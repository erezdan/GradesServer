using GradesServer.Data;
using GradesServer.DTOs;
using Microsoft.EntityFrameworkCore;

namespace GradesServer.Services
{
    public class ReportService : IReportService
    {
        private readonly GradesDbContext _context;

        public ReportService(GradesDbContext context)
        {
            _context = context;
        }

        public async Task<StudentReportDto> GetStudentReportAsync(int snapshotId)
        {
            var subjectZones = await _context.SubjectZones
                .Where(sz => sz.SnapshotId == snapshotId)
                .Select(sz => new { sz.ZoneId, sz.SubjectId })
                .ToListAsync();

            var zones = await _context.Zones
                .Where(z => subjectZones.Select(sz => sz.ZoneId).Contains(z.ZoneId))
                .Select(z => new { z.ZoneId, z.ZoneName })
                .ToListAsync();

            var zoneScores = new List<ZoneScoreCalculatedDto>();

            foreach (var zone in zones)
            {
                var questionIds = await _context.ZonesQuestions
                    .Where(zq => zq.SnapshotId == snapshotId && zq.ZoneId == zone.ZoneId)
                    .Select(zq => zq.QuestionId)
                    .ToListAsync();

                var relevantQuestions = await _context.Questions
                    .Where(q => q.SnapshotId == snapshotId && questionIds.Contains(q.QuestionId) && q.IsRelevant && q.Score.HasValue)
                    .Select(q => q.Score!.Value)
                    .ToListAsync();

                if (relevantQuestions.Any())
                {
                    zoneScores.Add(new ZoneScoreCalculatedDto
                    {
                        ZoneId = zone.ZoneId,
                        ZoneName = zone.ZoneName,
                        Score = relevantQuestions.Average()
                    });
                }
            }

            return new StudentReportDto
            {
                Title = "Student report",
                CreatedAt = DateTime.UtcNow,
                Top3Zones = zoneScores.OrderByDescending(z => z.Score).Take(3).ToList(),
                Bottom3Zones = zoneScores.OrderBy(z => z.Score).Take(3).ToList(),
                Under60Zones = zoneScores.Where(z => z.Score < 60).ToList()
            };
        }

        public async Task<PrincipalReportDto> GetPrincipalReportAsync(List<int> snapshotIds)
        {
            var allZQ = await _context.ZonesQuestions
                .Where(zq => snapshotIds.Contains(zq.SnapshotId))
                .ToListAsync();

            var allQ = await _context.Questions
                .Where(q => snapshotIds.Contains(q.SnapshotId) && q.IsRelevant && q.Score.HasValue)
                .Select(q => new { q.SnapshotId, q.QuestionId, q.Score })
                .ToListAsync();

            var zoneScores = new Dictionary<int, List<int>>();

            foreach (var zq in allZQ)
            {
                var score = allQ.FirstOrDefault(q => q.SnapshotId == zq.SnapshotId && q.QuestionId == zq.QuestionId)?.Score;
                if (score != null)
                {
                    if (!zoneScores.ContainsKey(zq.ZoneId))
                        zoneScores[zq.ZoneId] = new List<int>();

                    zoneScores[zq.ZoneId].Add(score.Value);
                }
            }

            var worstZone = zoneScores
                .Where(z => z.Value.Any())
                .Select(z => new { ZoneId = z.Key, Avg = z.Value.Average() })
                .OrderBy(z => z.Avg)
                .FirstOrDefault();

            string zoneName = worstZone != null
                ? await _context.Zones.Where(z => z.ZoneId == worstZone.ZoneId).Select(z => z.ZoneName).FirstOrDefaultAsync() ?? "Unknown"
                : "Unknown";

            return new PrincipalReportDto
            {
                Title = "Principal Report",
                CreatedAt = DateTime.UtcNow,
                LowestZone = worstZone == null ? null : new LowestZoneDto
                {
                    ZoneId = worstZone.ZoneId,
                    ZoneName = zoneName,
                    AverageScore = worstZone.Avg
                }
            };
        }
    }
}
