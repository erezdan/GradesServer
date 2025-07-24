using GradesServer.Data;
using GradesServer.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GradesServer.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class QuestionsController : ControllerBase
    {
        private readonly GradesDbContext _context;

        public QuestionsController(GradesDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Question>>> GetQuestions([FromQuery] int snapshotId)
        {
            var questions = await _context.Questions
                .Where(q => q.SnapshotId == snapshotId)
                .ToListAsync();

            return Ok(questions);
        }

        [HttpPost]
        public async Task<ActionResult> CreateQuestion([FromBody] Question dto)
        {
            if (dto.Score is < 0 or > 100)
                return BadRequest("Score must be between 0 and 100");

            var question = new Question
            {
                SnapshotId = dto.SnapshotId,
                TestId = dto.TestId,
                QuestionText = dto.QuestionText,
                Score = dto.Score,
                IsRelevant = dto.IsRelevant
            };

            _context.Questions.Add(question);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetQuestions), new { snapshotId = question.SnapshotId }, question);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> UpdateQuestion(int id, [FromBody] Question dto)
        {
            var question = await _context.Questions.FindAsync(id);
            if (question == null)
                return NotFound();

            if (dto.Score is < 0 or > 100)
                return BadRequest("Score must be between 0 and 100");

            question.QuestionText = dto.QuestionText;
            question.Score = dto.Score;
            question.IsRelevant = dto.IsRelevant;

            await _context.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteQuestion(int id)
        {
            var question = await _context.Questions.FindAsync(id);
            if (question == null)
                return NotFound();

            _context.Questions.Remove(question);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
