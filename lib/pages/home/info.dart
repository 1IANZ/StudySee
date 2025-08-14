import 'package:flutter/material.dart';
import 'package:hbfu_alex/src/rust/api/simple.dart';
import 'package:hbfu_alex/src/rust/api/jwxt/info.dart';

class Info extends StatefulWidget {
  final bool isMobile;

  const Info({super.key, required this.isMobile});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> with TickerProviderStateMixin {
  late Future<StudentInfo> _studentFuture;
  bool _showIdNumber = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _studentFuture = fetchStudentData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<StudentInfo> fetchStudentData() async {
    final student = await apiStudentInfo();
    _animationController.forward();
    return student;
  }

  String _maskIdNumber(String idNumber) {
    if (idNumber.length >= 8) {
      return '${idNumber.substring(0, 4)}${'*' * (idNumber.length - 8)}${idNumber.substring(idNumber.length - 4)}';
    }
    return idNumber;
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isSensitive = false,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isSensitive && !_showIdNumber
                        ? _maskIdNumber(value)
                        : value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                if (isSensitive) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showIdNumber = !_showIdNumber;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _showIdNumber ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(StudentInfo student, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final screenHeight = MediaQuery.of(context).size.height;

    const double topCardHeight = 100;
    const double verticalPadding = 32;

    final double availableHeight =
        screenHeight - topCardHeight - verticalPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        const int three = 3;
        const double spacing = 10;
        final cardWidth = (maxWidth - 52) / three;
        final lastCardWidth = maxWidth;

        final totalVerticalSpacing = (three - 1) * spacing;
        final rowHeight = (availableHeight - totalVerticalSpacing) / three - 42;

        Widget card(
          String title,
          String content,
          IconData icon,
          Color color, {
          bool isSensitive = false,
          double? width,
          double? height,
        }) {
          return SizedBox(
            width: width ?? cardWidth,
            height: height ?? rowHeight,
            child: _buildCompactInfoCard(
              context,
              title,
              content,
              icon,
              color,
              isSensitive: isSensitive,
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: topCardHeight,
                  child: Card(
                    elevation: 2,
                    shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primaryContainer.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 28,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  student.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student.studentId,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    card(
                      '性别',
                      student.gender,
                      Icons.person_outline,
                      colorScheme.primary,
                    ),
                    SizedBox(width: spacing),
                    card(
                      '院系',
                      student.department,
                      Icons.business,
                      colorScheme.secondary,
                    ),
                    SizedBox(width: spacing),
                    card(
                      '专业',
                      student.major,
                      Icons.school,
                      colorScheme.tertiary,
                    ),
                  ],
                ),

                SizedBox(height: spacing),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    card('班级', student.className, Icons.groups, Colors.orange),
                    SizedBox(width: spacing),
                    card(
                      '入学日期',
                      student.admissionDate,
                      Icons.calendar_today,
                      Colors.green,
                    ),
                    SizedBox(width: spacing),
                    card(
                      '录取学号',
                      student.admissionNumber,
                      Icons.confirmation_number,
                      Colors.purple,
                    ),
                  ],
                ),

                SizedBox(height: spacing),

                card(
                  '身份证号',
                  student.idNumber,
                  Icons.badge,
                  Colors.red,
                  isSensitive: true,
                  width: lastCardWidth,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isSensitive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 42, color: color),
                if (isSensitive) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showIdNumber = !_showIdNumber;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        _showIdNumber ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),

            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            Text(
              isSensitive && !_showIdNumber ? _maskIdNumber(value) : value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(StudentInfo student, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 8,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildHeader(student, context),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '基本信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('性别', student.gender, context: context),
                _buildInfoRow('院系', student.department, context: context),
                _buildInfoRow('专业', student.major, context: context),
                _buildInfoRow('班级', student.className, context: context),
                const SizedBox(height: 16),
                Text(
                  '入学信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('入学日期', student.admissionDate, context: context),
                _buildInfoRow(
                  '入学学号',
                  student.admissionNumber,
                  context: context,
                ),
                const SizedBox(height: 16),
                Text(
                  '个人信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  '身份证号',
                  student.idNumber,
                  isSensitive: true,
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(StudentInfo student, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: colorScheme.surface, width: 2),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.studentId,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.9,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FutureBuilder<StudentInfo>(
        future: _studentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    '加载失败',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final student = snapshot.data!;
            return FadeTransition(
              opacity: _fadeAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = !widget.isMobile;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: isDesktop
                        ? _buildDesktopLayout(student, context)
                        : _buildMobileLayout(student, context),
                  );
                },
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无数据',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
