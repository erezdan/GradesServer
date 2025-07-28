using Microsoft.AspNetCore.Mvc;
using GradesServer.Data;
using Microsoft.EntityFrameworkCore;
using GradesServer.DTOs;

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

        // GET api/reports/student
        [HttpGet("student/{snapshotId}")]
        public async Task<IActionResult> GetStudentReport(int snapshotId)
        {
            // Step 1: Get all SubjectIds for the snapshot
            var subjectIds = await _context.Subjects
                .Where(s => s.SnapshotId == snapshotId)
                .Select(s => s.SubjectId)
                .ToListAsync();

            var allZoneScores = new List<ZoneScoreDto>();

            // Step 2: Loop over each subject and call SP
            foreach (var subjectId in subjectIds)
            {
                var zoneScores = await _context.Set<ZoneScoreDto>()
                    .FromSqlInterpolated(
                        $"EXEC calculate_score_per_snapshot {snapshotId}, {subjectId}")
                    .ToListAsync();

                allZoneScores.AddRange(zoneScores);
            }

            // Step 3: Flatten and extract zone scores
            var simplified = allZoneScores
                .Select(z => new
                {
                    z.ZoneName,
                    Score = z.NationalTestScores ?? 0
                })
                .ToList();

            // Step 4: Analyze
            var top3 = simplified.OrderByDescending(z => z.Score).Take(3).ToList();
            var bottom3 = simplified.OrderBy(z => z.Score).Take(3).ToList();
            var under60 = simplified.Where(z => z.Score < 60).ToList();

            // Step 5: Return result
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
