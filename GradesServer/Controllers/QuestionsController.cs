using GradesServer.Data;
using GradesServer.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GradesServer.DTOs;

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
        public async Task<ActionResult<IEnumerable<ReturnedQuestionDto>>> GetQuestions([FromQuery] int snapshotId)
        {
            var questions = await _context.Questions
                .Where(q => q.SnapshotId == snapshotId)
                .Select(q => new ReturnedQuestionDto
                {
                    QuestionId = q.QuestionId,
                    QuestionText = q.QuestionText,
                    Score = q.Score,
                    IsRelevant = q.IsRelevant
                })
                .ToListAsync();

            return Ok(questions);
        }

        [HttpPost]
        public async Task<ActionResult> CreateQuestion([FromBody] QuestionDto dto)
        {
            if (dto.Score is < 0 or > 100)
                return BadRequest("Score must be between 0 and 100");

            if (dto.TestId == null)
                return BadRequest("TestId is required");

            if (string.IsNullOrWhiteSpace(dto.QuestionText))
                return BadRequest("QuestionText is required");

            var question = new Question
            {
                SnapshotId = dto.SnapshotId,
                TestId = dto.TestId.Value,
                QuestionText = dto.QuestionText,
                Score = dto.Score,
                IsRelevant = dto.IsRelevant
            };

            _context.Questions.Add(question);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetQuestions), new { snapshotId = question.SnapshotId }, question);
        }

        [HttpPut("{snapshotId:int}/{questionId:int}")]
        public async Task<ActionResult> UpdateQuestion(int snapshotId, int questionId, [FromBody] UpdateQuestionDto dto)
        {
            var question = await FindQuestion(snapshotId, questionId);
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

        [HttpDelete("{snapshotId:int}/{questionId:int}")]
        public async Task<ActionResult> DeleteQuestion(int snapshotId, int questionId)
        {
            var question = await FindQuestion(snapshotId, questionId);
            if (question == null)
                return NotFound();

            _context.Questions.Remove(question);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private Task<Question?> FindQuestion(int snapshotId, int questionId) =>
            _context.Questions.FirstOrDefaultAsync(q => q.SnapshotId == snapshotId && q.QuestionId == questionId);
    }
}
