using Microsoft.AspNetCore.Mvc;
using GradesServer.Data;
using Microsoft.EntityFrameworkCore;

namespace GradesServer.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReportsController : ControllerBase
    {
        private readonly GradesDbContext _context;

        public ReportsController(GradesDbContext context)
        {
            _context = context;
        }

        // GET api/reports/student/5
        [HttpGet("student/{snapshotId}")]
        public async Task<IActionResult> GetStudentReport(int snapshotId)
        {
            var subjectZones = await _context.SubjectZones
                .Where(sz => sz.SnapshotId == snapshotId)
                .Join(_context.Zones,
                    sz => sz.ZoneId,
                    z => z.ZoneId,
                    (sz, z) => new
                    {
                        sz.ZoneId,
                        sz.SnapshotId,
                        ZoneName = z.ZoneName
                    })
                .ToListAsync();

            var zoneScores = new List<(int ZoneId, string ZoneName, double Score)>();

            foreach (var sz in subjectZones)
            {
                var questionScores = await _context.ZonesQuestions
                    .Where(zq => zq.SnapshotId == snapshotId && zq.ZoneId == sz.ZoneId)
                    .Join(_context.Questions,
                        zq => new { zq.SnapshotId, zq.QuestionId },
                        q => new { q.SnapshotId, q.QuestionId },
                        (zq, q) => new { q.Score, q.IsRelevant })
                    .Where(q => q.IsRelevant && q.Score.HasValue)
                    .Select(q => q.Score!.Value)
                    .ToListAsync();

                if (questionScores.Any())
                {
                    double avg = questionScores.Average();
                    zoneScores.Add((sz.ZoneId, sz.ZoneName, avg));
                }
            }

            var top3 = zoneScores.OrderByDescending(z => z.Score).Take(3).ToList();
            var bottom3 = zoneScores.OrderBy(z => z.Score).Take(3).ToList();
            var under60 = zoneScores.Where(z => z.Score < 60).ToList();

            return Ok(new
            {
                Title = "Student report",
                CreatedAt = DateTime.UtcNow,
                Top3Zones = top3,
                Bottom3Zones = bottom3,
                Under60Zones = under60
            });
        }

        // POST api/reports/principal
        [HttpPost("principal")]
        public async Task<IActionResult> GetPrincipalReport([FromBody] List<int> snapshotIds)
        {
            var zoneScoresDict = new Dictionary<int, List<int>>();

            var questionData = await _context.ZonesQuestions
                .Where(zq => snapshotIds.Contains(zq.SnapshotId))
                .Join(_context.Questions,
                    zq => new { zq.SnapshotId, zq.QuestionId },
                    q => new { q.SnapshotId, q.QuestionId },
                    (zq, q) => new { zq.ZoneId, q.Score, q.IsRelevant })
                .Where(q => q.IsRelevant && q.Score.HasValue)
                .ToListAsync();

            foreach (var item in questionData)
            {
                if (!zoneScoresDict.ContainsKey(item.ZoneId))
                    zoneScoresDict[item.ZoneId] = new List<int>();

                zoneScoresDict[item.ZoneId].Add(item.Score!.Value);
            }

            var avgZoneScores = zoneScoresDict
                .Select(z => new
                {
                    ZoneId = z.Key,
                    AverageScore = z.Value.Average()
                })
                .OrderBy(z => z.AverageScore)
                .ToList();

            var worstZone = avgZoneScores.FirstOrDefault();
            string? worstZoneName = worstZone != null
                ? await _context.Zones
                    .Where(z => z.ZoneId == worstZone.ZoneId)
                    .Select(z => z.ZoneName)
                    .FirstOrDefaultAsync()
                : null;

            return Ok(new
            {
                Title = "Principal Report",
                CreatedAt = DateTime.UtcNow,
                LowestZone = new
                {
                    ZoneId = worstZone?.ZoneId,
                    ZoneName = worstZoneName,
                    AverageScore = worstZone?.AverageScore
                }
            });
        }
    }
}
