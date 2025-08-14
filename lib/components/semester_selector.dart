// 学期选择器封装组件
import 'package:flutter/material.dart';
import 'package:hbfu_alex/src/rust/api/jwxt/semester.dart';

class SemesterSelector extends StatelessWidget {
  final List<SemesterInfo> semesters;
  final SemesterInfo? selectedSemester;
  final Function(SemesterInfo) onChanged;
  final bool showSelector;

  const SemesterSelector({
    super.key,
    required this.semesters,
    required this.selectedSemester,
    required this.onChanged,
    this.showSelector = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!showSelector || semesters.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: DropdownButtonHideUnderline(
          child: DropdownButton<SemesterInfo>(
            value: selectedSemester,
            isExpanded: true,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: theme.primaryColor,
                size: 16,
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            dropdownColor: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            elevation: 8,
            onChanged: (semester) {
              if (semester != null) {
                onChanged(semester);
              }
            },
            items: semesters.map((semester) {
              final isSelected = selectedSemester == semester;
              return DropdownMenuItem(
                value: semester,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.calendar_month,
                        color: isSelected
                            ? theme.primaryColor
                            : theme.colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          semester.key,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.primaryColor
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
