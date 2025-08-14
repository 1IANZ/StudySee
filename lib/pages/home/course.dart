import 'package:flutter/material.dart';

import 'package:hbfu_alex/src/rust/api/jwxt/course.dart';
import 'package:hbfu_alex/src/rust/api/jwxt/semester.dart';
import 'package:hbfu_alex/components/semester_selector.dart';
import 'package:hbfu_alex/src/rust/api/simple.dart';

class Course extends StatefulWidget {
  final List<SemesterInfo> semesters;
  final bool isMobile;
  const Course({super.key, required this.semesters, required this.isMobile});
  @override
  State<Course> createState() => _CourseState();
}

class _CourseState extends State<Course> {
  SemesterInfo? _selectedSemester;
  List<CourseSchedule> _courses = [];
  bool _isLoading = false;
  bool _viewByWeek = true;

  final ScrollController _mobileScrollController = ScrollController();

  final Set<String> _expandedDays = {};
  final Set<String> _expandedSlots = {};

  Future<void> _scrollToKey(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.0,
    );
  }

  List<String> _sortTimeSlotsList(Iterable<String> slots) {
    final sorted = slots.toList();
    sorted.sort((a, b) {
      try {
        final aStart = a.split('~').first.split('-').first.replaceAll(':', '');
        final bStart = b.split('~').first.split('-').first.replaceAll(':', '');
        return int.parse(aStart).compareTo(int.parse(bStart));
      } catch (_) {
        return a.compareTo(b);
      }
    });
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    if (widget.semesters.isNotEmpty) {
      _selectedSemester = widget.semesters[0];
      _fetchCourse(_selectedSemester!);
    }
  }

  Future<void> _fetchCourse(SemesterInfo semester) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await apiCourse(semester: semester.value);
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _courses = [];
        _isLoading = false;
      });
    }
  }

  Map<String, Map<String, List<CourseSchedule>>> _organizeCourses() {
    Map<String, Map<String, List<CourseSchedule>>> organized = {};

    const weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    for (String day in weekDays) {
      organized[day] = {};
    }

    for (CourseSchedule course in _courses) {
      String dayKey = course.dayOfWeek;

      if (!organized.containsKey(dayKey)) {
        organized[dayKey] = {};
      }

      if (!organized[dayKey]!.containsKey(course.timeRange)) {
        organized[dayKey]![course.timeRange] = [];
      }

      organized[dayKey]![course.timeRange]!.add(course);
    }

    return organized;
  }

  List<String> _getAllTimeSlots() {
    if (_courses.isEmpty) {
      return [];
    }

    Set<String> timeSlots = {};
    for (CourseSchedule course in _courses) {
      timeSlots.add(course.timeRange);
    }

    List<String> sortedSlots = timeSlots.toList();
    sortedSlots.sort((a, b) {
      try {
        String timeA = a.split('~')[0].split('-')[0].replaceAll(':', '');
        String timeB = b.split('~')[0].split('-')[0].replaceAll(':', '');
        return int.parse(timeA).compareTo(int.parse(timeB));
      } catch (e) {
        return a.compareTo(b);
      }
    });

    return sortedSlots;
  }

  Widget _buildSemesterSelector(ThemeData theme) {
    if (widget.semesters.length <= 1) return const SizedBox.shrink();
    return SemesterSelector(
      semesters: widget.semesters,
      selectedSemester: _selectedSemester,
      onChanged: (semester) {
        setState(() {
          _selectedSemester = semester;
        });
        _fetchCourse(semester);
      },
    );
  }

  Widget _buildCourseCard(CourseSchedule course, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showCourseDetail(course, theme),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(5),
        height: 90,
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 3,
              child: Text(
                course.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),

            if (course.classroom.isNotEmpty)
              Flexible(
                child: Row(
                  children: [
                    Icon(
                      Icons.room,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        course.classroom,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Flexible(
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.weeks,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseDetail(CourseSchedule course, ThemeData theme) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '课程详情',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  '课程名称',
                                  course.name,
                                  Icons.book,
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  '授课教师',
                                  course.teacher,
                                  Icons.person,
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  '上课时间',
                                  '${course.dayOfWeek} ${course.timeRange}',
                                  Icons.schedule,
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  '上课地点',
                                  course.classroom,
                                  Icons.room,
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  '周次',
                                  course.weeks,
                                  Icons.date_range,
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  '课时长度',
                                  course.duration,
                                  Icons.timer,
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  '节次',
                                  course.section.toString(),
                                  Icons.format_list_numbered,
                                  theme,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: theme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCourseTableByTime(ThemeData theme) {
    final organized = _organizeCourses();
    const weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

    final timeSlots = _getAllTimeSlots();
    if (timeSlots.isEmpty) {
      return const SizedBox.shrink();
    }
    final slotKeys = {for (final s in timeSlots) s: GlobalKey()};
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      controller: _mobileScrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: timeSlots.map((slot) {
                  final sec = _getSectionFromTimeSlot(slot);
                  final selected = _expandedSlots.contains(slot);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: selected
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      side: BorderSide(color: cs.outlineVariant),
                      label: Text(
                        sec.isEmpty ? slot : sec,
                        style: TextStyle(
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        setState(() {
                          _expandedSlots.add(slot);
                        });
                        await _scrollToKey(slotKeys[slot]!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          ...timeSlots.map((slot) {
            final coursesByDay = <String, List<CourseSchedule>>{};
            for (final day in weekDays) {
              final courses = organized[day]?[slot] ?? [];
              if (courses.isNotEmpty) {
                coursesByDay[day] = courses;
              }
            }
            if (coursesByDay.isEmpty) return const SizedBox.shrink();

            final expanded = _expandedSlots.contains(slot);
            final secText = _getSectionFromTimeSlot(slot);
            final timeRanges = slot.split('-');

            return Container(
              key: slotKeys[slot],
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: expanded,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  leading: Icon(
                    Icons.schedule,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  title: Text(
                    secText.isEmpty ? slot : secText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    timeRanges.join(' / '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  onExpansionChanged: (open) {
                    setState(() {
                      if (open) {
                        _expandedSlots.add(slot);
                      } else {
                        _expandedSlots.remove(slot);
                      }
                    });
                  },
                  children: [
                    ...coursesByDay.entries.map((entry) {
                      final day = entry.key;
                      final courses = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  day,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...courses.map((c) => _buildCourseCard(c, theme)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDesktopCourseTable(ThemeData theme) {
    final organizedCourses = _organizeCourses();
    const weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final timeSlots = _getAllTimeSlots();

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
        child: Table(
          border: TableBorder.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
              ),
              children: [
                _buildTableHeader('时间', theme),
                ...weekDays.map((day) => _buildTableHeader(day, theme)),
              ],
            ),

            ...timeSlots.map((timeSlot) {
              return TableRow(
                children: [
                  _buildTimeSlotCell(timeSlot, theme),
                  ...weekDays.map((day) {
                    final courses = organizedCourses[day]?[timeSlot] ?? [];
                    return _buildCourseCell(courses, theme);
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTimeSlotCell(String timeSlot, ThemeData theme) {
    String sectionText = _getSectionFromTimeSlot(timeSlot);

    List<String> timeRanges = timeSlot.split('-');

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            sectionText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),

          ...timeRanges.map(
            (range) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                range.trim(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSectionFromTimeSlot(String timeSlot) {
    for (CourseSchedule course in _courses) {
      if (course.timeRange == timeSlot) {
        return '第${course.section}大节';
      }
    }
    return '';
  }

  Widget _buildCourseCell(List<CourseSchedule> courses, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      height: 110,
      child: courses.isEmpty
          ? null
          : ListView.builder(
              shrinkWrap: true,
              itemCount: courses.length,
              itemBuilder: (context, index) {
                return _buildCourseCard(courses[index], theme);
              },
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
            Icons.calendar_today_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无课程',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前学期还没有课程安排',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String text,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '查看方式',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  '按节次',
                  !_viewByWeek,
                  () => setState(() => _viewByWeek = false),
                  theme,
                ),
                _buildToggleButton(
                  '按星期',
                  _viewByWeek,
                  () => setState(() => _viewByWeek = true),
                  theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCourseTableByWeek(ThemeData theme) {
    final organized = _organizeCourses();
    const weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

    final daysWithCourses = weekDays
        .where((d) => (organized[d] ?? {}).isNotEmpty)
        .toList();

    final dayKeys = {for (final d in daysWithCourses) d: GlobalKey()};

    final cs = theme.colorScheme;

    return SingleChildScrollView(
      controller: _mobileScrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (daysWithCourses.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: daysWithCourses.map((day) {
                    final selected = _expandedDays.contains(day);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: selected
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        side: BorderSide(color: cs.outlineVariant),
                        label: Text(
                          day,
                          style: TextStyle(
                            color: selected
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          setState(() {
                            _expandedDays.add(day);
                          });
                          await _scrollToKey(dayKeys[day]!);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          ...daysWithCourses.map((day) {
            final daySchedule = organized[day]!;
            final timeSlots = _sortTimeSlotsList(daySchedule.keys);
            final expanded = _expandedDays.contains(day);

            return Container(
              key: dayKeys[day],
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: expanded,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  leading: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  title: Text(
                    day,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '共 ${timeSlots.length} 个节次',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  onExpansionChanged: (open) {
                    setState(() {
                      if (open) {
                        _expandedDays.add(day);
                      } else {
                        _expandedDays.remove(day);
                      }
                    });
                  },
                  children: [
                    ...timeSlots.map((slot) {
                      final courses = daySchedule[slot]!;
                      final sectionText = _getSectionFromTimeSlot(slot);
                      final timeRanges = slot.split('-');

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  sectionText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    timeRanges.join(' / '),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...courses.map((c) => _buildCourseCard(c, theme)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
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
        if (widget.isMobile && !_isLoading && _courses.isNotEmpty)
          _buildViewToggle(theme),
        Expanded(
          child: _isLoading
              ? _buildLoadingIndicator(theme)
              : _courses.isEmpty
              ? _buildEmptyState(theme)
              : widget.isMobile
              ? (_viewByWeek
                    ? _buildMobileCourseTableByWeek(theme)
                    : _buildMobileCourseTableByTime(theme))
              : _buildDesktopCourseTable(theme),
        ),
      ],
    );
  }
}
