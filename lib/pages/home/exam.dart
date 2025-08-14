import 'package:flutter/material.dart';
import 'package:hbfu_alex/src/rust/api/simple.dart';
import 'package:hbfu_alex/src/rust/api/jwxt/exam.dart';
import 'package:hbfu_alex/src/rust/api/jwxt/semester.dart';
import 'package:hbfu_alex/components/semester_selector.dart';

class Exam extends StatefulWidget {
  final List<SemesterInfo> semesters;
  final bool isMobile;

  const Exam({super.key, required this.semesters, required this.isMobile});

  @override
  State<Exam> createState() => _ExamState();
}

class _ExamState extends State<Exam> {
  SemesterInfo? _selectedSemester;
  List<ExamSchedule> _exams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.semesters.isNotEmpty) {
      _selectedSemester = widget.semesters[0];
      _fetchExam(_selectedSemester!);
    }
  }

  Future<void> _fetchExam(SemesterInfo semester) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exams = await apiExam(semester: semester.value);

      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _exams = [];
        _isLoading = false;
      });
    }
  }

  List<ExamSchedule> _getSortedExams() {
    List<ExamSchedule> sortedExams = List.from(_exams);
    sortedExams.sort((a, b) {
      try {
        DateTime dateTimeA = _parseExamDateTime(a.examTime);
        DateTime dateTimeB = _parseExamDateTime(b.examTime);
        return dateTimeA.compareTo(dateTimeB);
      } catch (e) {
        // 如果解析失败，按字符串排序
        return a.examTime.compareTo(b.examTime);
      }
    });
    return sortedExams;
  }

  DateTime _parseExamDateTime(String examTime) {
    List<String> parts = examTime.split(' ');
    if (parts.length != 2) throw FormatException('Invalid time format');

    String datePart = parts[0];
    String timePart = parts[1];

    List<String> dateComponents = datePart.split('-');
    if (dateComponents.length != 3) {
      throw FormatException('Invalid date format');
    }

    int year = int.parse(dateComponents[0]);
    int month = int.parse(dateComponents[1]);
    int day = int.parse(dateComponents[2]);

    String startTime = timePart.split('~')[0];
    List<String> startTimeComponents = startTime.split(':');
    if (startTimeComponents.length != 2) {
      throw FormatException('Invalid start time format');
    }

    int startHour = int.parse(startTimeComponents[0]);
    int startMinute = int.parse(startTimeComponents[1]);

    return DateTime(year, month, day, startHour, startMinute);
  }

  Widget _buildSemesterSelector(ThemeData theme) {
    return SemesterSelector(
      semesters: widget.semesters,
      selectedSemester: _selectedSemester,
      onChanged: (semester) {
        setState(() {
          _selectedSemester = semester;
        });
        _fetchExam(semester);
      },
    );
  }

  Widget _buildExamCard(ExamSchedule exam, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 课程名称和状态
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exam.courseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getExamStatusColor(
                    exam.examTime,
                    theme,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getExamStatus(exam.examTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getExamStatusColor(exam.examTime, theme),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 课程编号
          _buildInfoRow(Icons.code, '课程编号', exam.courseCode, theme),
          const SizedBox(height: 8),

          // 考试时间
          _buildInfoRow(Icons.schedule, '考试时间', exam.examTime, theme),
          const SizedBox(height: 8),

          // 考试地点
          _buildInfoRow(Icons.room, '考试地点', exam.examLocation, theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // 获取考试状态
  String _getExamStatus(String examTime) {
    try {
      DateTime now = DateTime.now();

      // 解析考试时间格式：2025-06-24 08:00~09:40
      List<String> parts = examTime.split(' ');
      if (parts.length != 2) return '待考试';

      String datePart = parts[0]; // 2025-06-24
      String timePart = parts[1]; // 08:00~09:40

      // 解析日期
      List<String> dateComponents = datePart.split('-');
      if (dateComponents.length != 3) return '待考试';

      int year = int.parse(dateComponents[0]);
      int month = int.parse(dateComponents[1]);
      int day = int.parse(dateComponents[2]);

      // 解析时间
      List<String> timeRange = timePart.split('~');
      if (timeRange.length != 2) return '待考试';

      List<String> startTimeComponents = timeRange[0].split(':');
      List<String> endTimeComponents = timeRange[1].split(':');

      if (startTimeComponents.length != 2 || endTimeComponents.length != 2) {
        return '待考试';
      }

      int startHour = int.parse(startTimeComponents[0]);
      int startMinute = int.parse(startTimeComponents[1]);
      int endHour = int.parse(endTimeComponents[0]);
      int endMinute = int.parse(endTimeComponents[1]);

      // 创建考试开始和结束时间
      DateTime examStart = DateTime(year, month, day, startHour, startMinute);
      DateTime examEnd = DateTime(year, month, day, endHour, endMinute);

      // 判断考试状态
      if (now.isBefore(examStart)) {
        return '待考试';
      } else if (now.isAfter(examEnd)) {
        return '已结束';
      } else {
        return '进行中';
      }
    } catch (e) {
      return '待考试';
    }
  }

  // 获取考试状态颜色
  Color _getExamStatusColor(String examTime, ThemeData theme) {
    String status = _getExamStatus(examTime);
    switch (status) {
      case '已结束':
        return theme.colorScheme.onSurfaceVariant;
      case '进行中':
        return theme.colorScheme.error;
      case '待考试':
      default:
        return theme.primaryColor;
    }
  }

  Widget _buildMobileExamList(ThemeData theme) {
    final sortedExams = _getSortedExams();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedExams.length,
      itemBuilder: (context, index) {
        return _buildExamCard(sortedExams[index], theme);
      },
    );
  }

  Widget _buildDesktopExamList(ThemeData theme) {
    final sortedExams = _getSortedExams();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 表头
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: _buildTableHeader('序号', theme)),
                  Expanded(flex: 3, child: _buildTableHeader('课程编号', theme)),
                  Expanded(flex: 2, child: _buildTableHeader('课程名称', theme)),
                  Expanded(flex: 3, child: _buildTableHeader('考试时间', theme)),
                  Expanded(flex: 2, child: _buildTableHeader('考试地点', theme)),
                  Expanded(flex: 2, child: _buildTableHeader('状态', theme)),
                ],
              ),
            ),
            ...sortedExams.map((exam) => _buildDesktopExamRow(exam, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, ThemeData theme) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDesktopExamRow(ExamSchedule exam, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              exam.id.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              exam.courseCode,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              exam.courseName,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              exam.examTime,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              exam.examLocation,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getExamStatusColor(
                    exam.examTime,
                    theme,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getExamStatus(exam.examTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getExamStatusColor(exam.examTime, theme),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无考试安排',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前学期还没有考试安排',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildSemesterSelector(theme),
        Expanded(
          child: _isLoading
              ? _buildLoadingIndicator(theme)
              : _exams.isEmpty
              ? _buildEmptyState(theme)
              : widget.isMobile
              ? _buildMobileExamList(theme)
              : _buildDesktopExamList(theme),
        ),
      ],
    );
  }
}
