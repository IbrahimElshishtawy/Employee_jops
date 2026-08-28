import 'package:flutter/material.dart';
import '../../domain/entities/department.dart';
import 'department_card.dart';

class DepartmentGrid extends StatelessWidget {
  final List<Department> departments;
  final ValueChanged<Department> onDepartmentSelected;
  final String? selectedDepartmentId;

  const DepartmentGrid({
    super.key,
    required this.departments,
    required this.onDepartmentSelected,
    this.selectedDepartmentId,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.4,
      ),
      itemCount: departments.length,
      itemBuilder: (context, index) {
        final dept = departments[index];
        return DepartmentCard(
          department: dept,
          isSelected: selectedDepartmentId == dept.id,
          onTap: () => onDepartmentSelected(dept),
        );
      },
    );
  }
}
