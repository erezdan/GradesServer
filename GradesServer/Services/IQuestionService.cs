using GradesServer.DTOs;
using GradesServer.Models;

namespace GradesServer.Services
{
    public interface IQuestionService
    {
        Task<List<Question>> GetQuestionsAsync(int snapshotId);
        Task<Question> CreateQuestionAsync(QuestionDto dto);
        Task<bool> UpdateQuestionAsync(int questionId, QuestionDto dto);
        Task<bool> DeleteQuestionAsync(int questionId);
    }
}
