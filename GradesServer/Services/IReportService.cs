using GradesServer.DTOs;

namespace GradesServer.Services
{
    public interface IReportService
    {
        Task<StudentReportDto> GetStudentReportAsync(int snapshotId);
        Task<PrincipalReportDto> GetPrincipalReportAsync(List<int> snapshotIds);
    }
}
