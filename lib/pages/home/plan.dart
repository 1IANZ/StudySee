import 'package:flutter/material.dart';
import 'package:hbfu_alex/src/rust/api/simple.dart';
import 'package:hbfu_alex/src/rust/api/jwxt/plan.dart';

class Plan extends StatefulWidget {
  final bool isMobile;
  const Plan({super.key, required this.isMobile});
  @override
  State<Plan> createState() => _PlanState();
}

class _PlanState extends State<Plan> with TickerProviderStateMixin {
  ExecutionPlanResponse? _planResponse;
  bool _isLoading = false;
  final Map<String, List<ExecutionPlan>> _semesterPlans = {};
  int? _expandedSemesterIndex;
  final Map<String, int?> _expandedCourseIndex = {};
  int? _hoveredSemesterIndex;
  final Map<String, int?> _hoveredCourseIndex = {};

  @override
  void initState() {
    super.initState();
    _fetchPlan();
  }

  Future<void> _fetchPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final plan = await apiPlan();
      setState(() {
        _planResponse = plan;
        _isLoading = false;
        _processPlanData();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processPlanData() {
    if (_planResponse == null) return;

    _semesterPlans.clear();
    for (var plan in _planResponse!.plans) {
      if (!_semesterPlans.containsKey(plan.semester)) {
        _semesterPlans[plan.semester] = [];
      }
      _semesterPlans[plan.semester]!.add(plan);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: widget.isMobile
              ? _buildMobileSemestersList()
              : _buildSemestersTable(),
        ),
      ],
    );
  }

  Widget _buildMobileSemestersList() {
    final sortedSemesters = List<String>.from(_planResponse!.semesters)..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSemesters.length,
      itemBuilder: (context, index) {
        return _buildMobileSemesterCard(index, sortedSemesters[index]);
      },
    );
  }

  Widget _buildMobileSemesterCard(int index, String semester) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final plans = _semesterPlans[semester] ?? [];
    final isExpanded = _expandedSemesterIndex == index;

    final totalCredits = plans.fold<double>(
      0,
      (sum, plan) => sum + plan.credits,
    );
    final totalHours = plans.fold<double>(
      0,
      (sum, plan) => sum + plan.totalHours,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedSemesterIndex = isExpanded ? null : index;
            if (!isExpanded) {
              _expandedCourseIndex[semester] = null;
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        semester,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: cs.onSurface,
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 200),
                        tween: Tween(begin: 0.0, end: isExpanded ? 0.5 : 0.0),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 3.14159,
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatChip(
                        '${plans.length} 门课程',
                        Colors.blue.withValues(alpha: 0.1),
                        Colors.blue.shade700,
                      ),
                      _buildStatChip(
                        '$totalCredits 学分',
                        Colors.orange.withValues(alpha: 0.1),
                        Colors.orange.shade700,
                      ),
                      _buildStatChip(
                        '$totalHours 学时',
                        Colors.green.withValues(alpha: 0.1),
                        Colors.green.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            RepaintBoundary(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: isExpanded ? null : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isExpanded ? 1.0 : 0.0,
                  child: isExpanded
                      ? _buildMobileSemesterCourses(semester, plans)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSemesterCourses(
    String semester,
    List<ExecutionPlan> plans,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        children: plans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;
          return _buildMobileCourseItem(semester, plan, index, plans.length);
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCourseItem(
    String semester,
    ExecutionPlan plan,
    int index,
    int totalCount,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isExpanded = _expandedCourseIndex[semester] == index;

    return RepaintBoundary(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedCourseIndex[semester] = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          plan.courseName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 200),
                        tween: Tween(begin: 0.0, end: isExpanded ? 0.5 : 0.0),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 3.14159,
                            child: Icon(
                              Icons.expand_more,
                              size: 20,
                              color: cs.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildSmallChip(
                        '${plan.credits} 学分',
                        cs.primaryContainer,
                        cs.onPrimaryContainer,
                      ),
                      _buildSmallChip(
                        '${plan.totalHours} 学时',
                        cs.secondaryContainer,
                        cs.onSecondaryContainer,
                      ),
                      _buildCourseTypeChip(plan.courseType),
                    ],
                  ),
                ],
              ),
            ),
          ),
          RepaintBoundary(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: isExpanded ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isExpanded ? 1.0 : 0.0,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildMobileCourseDetail(plan),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          if (index < totalCount - 1)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileCourseDetail(ExecutionPlan plan) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileInfoRow('课程编号', plan.courseCode, Icons.tag_outlined),
          const SizedBox(height: 8),
          _buildMobileInfoRow('开课院系', plan.department, Icons.business_outlined),
          const SizedBox(height: 8),
          _buildMobileInfoRow(
            '考核方式',
            plan.assessmentMethod,
            Icons.grading_outlined,
          ),
          const SizedBox(height: 8),
          _buildMobileInfoRow(
            '考试类型',
            plan.isExam == 'true' ? '考试' : '考查',
            Icons.assignment_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(String label, String value, IconData icon) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: cs.onSurface),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSemestersTable() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sortedSemesters = List<String>.from(_planResponse!.semesters)..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        '学期',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 100,
                      child: Center(
                        child: Text(
                          '课程数',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 100,
                      child: Center(
                        child: Text(
                          '总学分',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 100,
                      child: Center(
                        child: Text(
                          '总学时',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedSemesters.length,
              itemBuilder: (context, index) {
                return _buildSemesterRow(index, sortedSemesters[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterRow(int index, String semester) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final plans = _semesterPlans[semester] ?? [];
    final isExpanded = _expandedSemesterIndex == index;
    final isHovered = _hoveredSemesterIndex == index;

    final totalCredits = plans.fold<double>(
      0,
      (sum, plan) => sum + plan.credits,
    );
    final totalHours = plans.fold<double>(
      0,
      (sum, plan) => sum + plan.totalHours,
    );

    final zebra = index.isOdd
        ? cs.surfaceContainerHighest.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.10 : 0.05,
          )
        : Colors.transparent;

    final rowColor = isHovered ? cs.primary.withValues(alpha: 0.05) : zebra;

    return Column(
      children: [
        RepaintBoundary(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredSemesterIndex = index),
            onExit: (_) => setState(() => _hoveredSemesterIndex = null),
            child: Material(
              color: rowColor,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedSemesterIndex = isExpanded ? null : index;
                    if (!isExpanded) {
                      _expandedCourseIndex[semester] = null;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          semester,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Center(
                          child: _buildStatChip(
                            '${plans.length}',
                            Colors.blue.withValues(alpha: 0.1),
                            Colors.blue.shade700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Center(
                          child: _buildStatChip(
                            '$totalCredits',
                            Colors.orange.withValues(alpha: 0.1),
                            Colors.orange.shade700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Center(
                          child: _buildStatChip(
                            '$totalHours',
                            Colors.green.withValues(alpha: 0.1),
                            Colors.green.shade700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween(
                              begin: 0.0,
                              end: isExpanded ? 0.5 : 0.0,
                            ),
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 3.14159,
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  color: cs.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isExpanded ? 1.0 : 0.0,
              child: isExpanded
                  ? _buildSemesterCourses(semester, plans)
                  : const SizedBox(),
            ),
          ),
        ),
        Container(height: 1, color: theme.dividerColor),
      ],
    );
  }

  Widget _buildStatChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSemesterCourses(String semester, List<ExecutionPlan> plans) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.05 : 0.02,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    '课程名称',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Center(
                    child: Text(
                      '学分',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      '课程类型',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              return _buildCourseRow(
                semester,
                plans[index],
                index,
                plans.length,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCourseRow(
    String semester,
    ExecutionPlan plan,
    int index,
    int totalCount,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isExpanded = _expandedCourseIndex[semester] == index;
    final isHovered = _hoveredCourseIndex[semester] == index;

    return RepaintBoundary(
      child: Column(
        children: [
          MouseRegion(
            onEnter: (_) =>
                setState(() => _hoveredCourseIndex[semester] = index),
            onExit: (_) => setState(() => _hoveredCourseIndex[semester] = null),
            child: Material(
              color: isHovered
                  ? cs.primary.withValues(alpha: 0.03)
                  : Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedCourseIndex[semester] = isExpanded ? null : index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          plan.courseName,
                          style: TextStyle(fontSize: 14, color: cs.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${plan.credits}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: _buildCourseTypeChip(plan.courseType),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween(
                              begin: 0.0,
                              end: isExpanded ? 0.5 : 0.0,
                            ),
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 3.14159,
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  color: cs.onSurfaceVariant,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          RepaintBoundary(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: isExpanded ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isExpanded ? 1.0 : 0.0,
                child: isExpanded
                    ? _buildInlineDetailCard(plan)
                    : const SizedBox(),
              ),
            ),
          ),
          if (index < totalCount - 1)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }

  Widget _buildInlineDetailCard(ExecutionPlan plan) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.18 : 0.42,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(
                  text: '${plan.credits} 学分',
                  icon: Icons.school_outlined,
                  bg: cs.primaryContainer,
                  fg: cs.onPrimaryContainer,
                ),
                _pill(
                  text: '${plan.totalHours} 学时',
                  icon: Icons.access_time,
                  bg: cs.secondaryContainer,
                  fg: cs.onSecondaryContainer,
                ),
                _pill(
                  text: plan.courseType,
                  icon: Icons.layers_outlined,
                  bg: _getCourseTypeColor(
                    plan.courseType,
                  ).withValues(alpha: 0.2),
                  fg: _getCourseTypeColor(plan.courseType),
                ),
                _pill(
                  text: plan.isExam == 'true' ? '考试' : '考查',
                  icon: Icons.assignment_outlined,
                  bg: plan.isExam == 'true'
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  fg: plan.isExam == 'true'
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth >= 560;
                final itemW = twoCol
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _infoTile(
                      '课程编号',
                      plan.courseCode,
                      Icons.tag_outlined,
                      itemW,
                    ),
                    _infoTile(
                      '开课院系',
                      plan.department,
                      Icons.business_outlined,
                      itemW,
                    ),
                    _infoTile(
                      '考核方式',
                      plan.assessmentMethod,
                      Icons.grading_outlined,
                      itemW,
                    ),
                    _infoTile(
                      '学期',
                      plan.semester,
                      Icons.calendar_today_outlined,
                      itemW,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseTypeChip(String courseType) {
    final color = _getCourseTypeColor(courseType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        courseType,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _getCourseTypeColor(String courseType) {
    switch (courseType.toLowerCase()) {
      case '必修':
        return Colors.red.shade700;
      case '限选':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _infoTile(String label, String value, IconData icon, double width) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
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

  Widget _pill({
    required String text,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
