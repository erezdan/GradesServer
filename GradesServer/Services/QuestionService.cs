using GradesServer.Data;
using GradesServer.DTOs;
using GradesServer.Models;
using Microsoft.EntityFrameworkCore;

namespace GradesServer.Services
{
    public class QuestionService : IQuestionService
    {
        private readonly GradesDbContext _context;

        public QuestionService(GradesDbContext context)
        {
            _context = context;
        }

        public async Task<List<Question>> GetQuestionsAsync(int snapshotId)
        {
            return await _context.Questions
                .Where(q => q.SnapshotId == snapshotId)
                .ToListAsync();
        }

        public async Task<Question> CreateQuestionAsync(QuestionDto dto)
        {
            if (dto.Score is < 0 or > 100)
                throw new ArgumentException("Score must be between 0 and 100");

            if (dto.TestId == null)
                throw new ArgumentException("TestId is required");

            var question = new Question
            {
                SnapshotId = dto.SnapshotId,
                QuestionText = dto.QuestionText,
                TestId = dto.TestId.Value,
                Score = dto.Score,
                IsRelevant = dto.IsRelevant
            };

            _context.Questions.Add(question);
            await _context.SaveChangesAsync();
            return question;
        }

        public async Task<bool> UpdateQuestionAsync(int questionId, QuestionDto dto)
        {
            var question = await _context.Questions.FindAsync(questionId);
            if (question == null) return false;

            if (dto.Score is < 0 or > 100)
                throw new ArgumentException("Score must be between 0 and 100");

            question.QuestionText = dto.QuestionText;
            question.IsRelevant = dto.IsRelevant;
            question.Score = dto.Score;

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteQuestionAsync(int questionId)
        {
            var question = await _context.Questions.FindAsync(questionId);
            if (question == null) return false;

            _context.Questions.Remove(question);
            await _context.SaveChangesAsync();
            return true;
        }
    }

}
