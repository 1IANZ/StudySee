import 'package:flutter/material.dart';
import 'package:hbfu_alex/src/rust/api/simple.dart';
import 'package:hbfu_alex/src/rust/api/jwxt/elective.dart';
import 'package:hbfu_alex/src/rust/api/jwxt/semester.dart';
import 'package:hbfu_alex/components/flush_bar.dart';
import 'package:hbfu_alex/components/semester_selector.dart';

class Elective extends StatefulWidget {
  final List<SemesterInfo> semesters;
  final bool isMobile;

  const Elective({super.key, required this.semesters, required this.isMobile});

  @override
  State<Elective> createState() => _ElectiveState();
}

class _ElectiveState extends State<Elective> {
  SemesterInfo? _selectedSemester;
  ElectiveResponse _electives = ElectiveResponse(credits: [], courses: []);
  bool _isLoading = false;
  bool _showCredits = false;
  final _expandedNotifier = ValueNotifier<int?>(null);
  final _hoveredNotifier = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    if (widget.semesters.isNotEmpty) {
      _selectedSemester = widget.semesters[0];
      _fetchElective(_selectedSemester!);
    }
  }

  @override
  void dispose() {
    _expandedNotifier.dispose();
    _hoveredNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchElective(SemesterInfo semester) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final electives = await apiElective(semester: semester.value);
      setState(() {
        _electives = electives;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showErrorFlushbar(context, '加载选课信息失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Column(
          children: [
            _buildSemesterSelector(theme),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _showCredits
                  ? _buildCreditsPage()
                  : _buildCoursesViewUnified(),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showCredits = !_showCredits;
              });
            },
            tooltip: _showCredits ? '查看选课信息' : '查看学分统计',
            child: Icon(_showCredits ? Icons.school : Icons.assessment),
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterSelector(ThemeData theme) {
    if (widget.semesters.length <= 1) return const SizedBox.shrink();
    return SemesterSelector(
      semesters: widget.semesters,
      selectedSemester: _selectedSemester,
      onChanged: (semester) {
        setState(() {
          _selectedSemester = semester;
          _expandedNotifier.value = null;
        });
        _fetchElective(semester);
      },
    );
  }

  Widget _buildCreditsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_electives.credits.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('暂无学分统计信息'),
              ),
            )
          else
            ..._electives.credits.map((credit) => _buildCreditCard(credit)),
        ],
      ),
    );
  }

  Widget _buildCreditCard(CreditInfo credit) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              credit.category,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildCreditStats(credit, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditStats(CreditInfo credit, ThemeData theme) {
    const spacing = 8.0;
    final maxItemWidth = widget.isMobile ? 110.0 : 150.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final idealRowWidth = 4 * maxItemWidth + 3 * spacing;
        final rowWidth = available < idealRowWidth ? available : idealRowWidth;
        final itemWidth = (rowWidth - 3 * spacing) / 4;

        return Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rowWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _StatCardCompact(
                        label: '必修',
                        value: credit.required_,
                        color: Colors.blue,
                        isMobile: widget.isMobile,
                      ),
                    ),
                    const SizedBox(width: spacing),
                    SizedBox(
                      width: itemWidth,
                      child: _StatCardCompact(
                        label: '限选',
                        value: credit.limited,
                        color: Colors.orange,
                        isMobile: widget.isMobile,
                      ),
                    ),
                    const SizedBox(width: spacing),
                    SizedBox(
                      width: itemWidth,
                      child: _StatCardCompact(
                        label: '任选',
                        value: credit.elective,
                        color: Colors.green,
                        isMobile: widget.isMobile,
                      ),
                    ),
                    const SizedBox(width: spacing),
                    SizedBox(
                      width: itemWidth,
                      child: _StatCardCompact(
                        label: '公选',
                        value: credit.public,
                        color: Colors.purple,
                        isMobile: widget.isMobile,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rowWidth),
                child: _buildTotalCompact(total: credit.total, theme: theme),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalCompact({required int total, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.10),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calculate_outlined, color: theme.primaryColor, size: 22),
          const SizedBox(width: 10),
          Text(
            '总学分',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              total.toString(),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesViewUnified() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                        '课程名称',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 80,
                      child: Center(
                        child: Text(
                          '学分',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
              itemCount: _electives.courses.length,
              itemBuilder: (context, index) {
                return _CourseRow(
                  course: _electives.courses[index],
                  index: index,
                  expandedNotifier: _expandedNotifier,
                  hoveredNotifier: _hoveredNotifier,
                  theme: theme,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final XqxkchInfo course;
  final int index;
  final ValueNotifier<int?> expandedNotifier;
  final ValueNotifier<int?> hoveredNotifier;
  final ThemeData theme;

  const _CourseRow({
    required this.course,
    required this.index,
    required this.expandedNotifier,
    required this.hoveredNotifier,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return ValueListenableBuilder<int?>(
      valueListenable: expandedNotifier,
      builder: (context, expandedIndex, child) {
        final isExpanded = expandedIndex == index;

        return ValueListenableBuilder<int?>(
          valueListenable: hoveredNotifier,
          builder: (context, hoveredIndex, child) {
            final isHovered = hoveredIndex == index;
            final zebra = index.isOdd
                ? cs.surfaceContainerHighest.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.10 : 0.05,
                  )
                : Colors.transparent;
            final rowColor = isHovered
                ? cs.primary.withValues(alpha: 0.05)
                : zebra;

            return MouseRegion(
              onEnter: (_) => hoveredNotifier.value = index,
              onExit: (_) => hoveredNotifier.value = null,
              child: Column(
                children: [
                  Material(
                    color: rowColor,
                    child: InkWell(
                      onTap: () {
                        expandedNotifier.value = isExpanded ? null : index;
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
                                course.courseName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: cs.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${course.credits}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimaryContainer,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.secondaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    course.courseAttribute,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Center(
                                child: AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: isExpanded
                          ? _CourseDetailCard(course: course, theme: theme)
                          : const SizedBox.shrink(),
                    ),
                  ),
                  Container(height: 1, color: theme.dividerColor),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CourseDetailCard extends StatelessWidget {
  final XqxkchInfo course;
  final ThemeData theme;

  const _CourseDetailCard({required this.course, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                _Pill(
                  text: '${course.credits} 学分',
                  icon: Icons.school_outlined,
                ),
                _Pill(
                  text: course.courseAttribute,
                  icon: Icons.layers_outlined,
                ),
                _StatusChip(status: course.selected),
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
                    _InfoTile(
                      label: '课程编号',
                      value: course.courseId,
                      icon: Icons.tag_outlined,
                      width: itemW,
                    ),
                    _InfoTile(
                      label: '开课院系',
                      value: course.department,
                      icon: Icons.business_outlined,
                      width: itemW,
                    ),
                    _InfoTile(
                      label: '学时',
                      value: '${course.hours} 学时',
                      icon: Icons.access_time,
                      width: itemW,
                    ),
                    _InfoTile(
                      label: '选课类型',
                      value: course.selectionType,
                      icon: Icons.category_outlined,
                      width: itemW,
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
}

class _StatCardCompact extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isMobile;

  const _StatCardCompact({
    required this.label,
    required this.value,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isMobile ? 68 : 74,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: isMobile ? 20 : 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double width;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return _Pill(text: status, icon: Icons.verified_outlined);
  }
}
