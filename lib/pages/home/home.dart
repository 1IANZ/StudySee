import 'package:flutter/material.dart';
import 'package:hbfu_alex/pages/home/dekt.dart';
import 'package:hbfu_alex/src/rust/api/simple.dart';
import 'package:hbfu_alex/src/rust/api/jwxt/semester.dart';
import 'package:hbfu_alex/components/window_control_button.dart';
import 'package:hbfu_alex/pages/home/course.dart';
import 'package:hbfu_alex/pages/home/elective.dart';
import 'package:hbfu_alex/pages/home/exam.dart';
import 'package:hbfu_alex/pages/home/plan.dart';
import 'package:hbfu_alex/pages/home/score.dart';
import 'package:hbfu_alex/pages/home/info.dart';
import 'package:hbfu_alex/pages/home/setting.dart';
import 'package:window_manager/window_manager.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  List<SemesterInfo> _semesters = [];
  List<SemesterInfo> _semestersAll = [];

  late List<Widget> _pages;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _navigationItems.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
    _loadSemesters();
    _loadSemestersAll();
  }

  Future<void> _loadSemestersAll() async {
    final semesters = await apiSemester(isAll: true);
    setState(() {
      _semestersAll = semesters;
    });
  }

  Future<void> _loadSemesters() async {
    final semesters = await apiSemester(isAll: false);
    setState(() {
      _semesters = semesters;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: '个人信息',
    ),
    NavigationItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: '课表查询',
    ),
    NavigationItem(
      icon: Icons.grade_outlined,
      selectedIcon: Icons.grade,
      label: '成绩查询',
    ),
    NavigationItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      label: '考试安排',
    ),
    NavigationItem(
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      label: '选课信息',
    ),
    NavigationItem(
      icon: Icons.timeline_outlined,
      selectedIcon: Icons.timeline,
      label: '执行计划',
    ),
    NavigationItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: '第二课堂',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: '个人中心',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    _pages = [
      Info(isMobile: isMobile),
      Course(semesters: _semesters, isMobile: isMobile),
      Score(semesters: _semestersAll, isMobile: isMobile),
      Exam(semesters: _semesters, isMobile: isMobile),
      Elective(semesters: _semesters, isMobile: isMobile),
      Plan(isMobile: isMobile),
      Dekt(isMobile: isMobile),
      Setting(isMobile: isMobile),
    ];

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_navigationItems[_selectedIndex].label),
          automaticallyImplyLeading: false,
        ),
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            Container(
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: theme.colorScheme.primary,
                      indicatorWeight: 3,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: _navigationItems
                          .map(
                            (item) => SizedBox(
                              height: 42,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _selectedIndex ==
                                            _navigationItems.indexOf(item)
                                        ? item.selectedIcon
                                        : item.icon,
                                    size: 20,
                                  ),
                                  Text(
                                    item.label,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(controller: _tabController, children: _pages),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          _buildDesktopSidebar(theme),

          Expanded(
            child: Column(
              children: [
                _buildAppBar(theme, _navigationItems[_selectedIndex]),

                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 230,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3 * value,
                          ),
                          theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.1 * value,
                          ),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.1,
                          ),
                          width: 1,
                        ),
                      ),
                    ),
                    child: DragToMoveArea(
                      child: Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1200),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, rotateValue, child) {
                              return Transform.rotate(
                                angle: (1 - rotateValue) * 0.5,
                                child: Transform.scale(
                                  scale: 0.8 + (0.2 * rotateValue),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary.withValues(
                                            alpha: 0.8,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .withValues(
                                                alpha: 0.3 * rotateValue,
                                              ),
                                          blurRadius: 8 * rotateValue,
                                          offset: Offset(0, 2 * rotateValue),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.transparent,
                                      child: Text(
                                        'A',
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HBFU ALEX',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: ListView.builder(
                itemCount: _navigationItems.length,
                itemBuilder: (context, index) {
                  final item = _navigationItems[index];
                  final isSelected = _selectedIndex == index;

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(-50 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.05,
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    setState(() => _selectedIndex = index),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                                .withValues(alpha: 0.2)
                                          : theme
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? item.selectedIcon
                                            : item.icon,
                                        key: ValueKey(isSelected),
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  title: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style:
                                        theme.textTheme.bodyLarge?.copyWith(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ) ??
                                        const TextStyle(),
                                    child: Text(item.label),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, NavigationItem navigationItem) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                navigationItem.label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const WindowControlButtons(),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
