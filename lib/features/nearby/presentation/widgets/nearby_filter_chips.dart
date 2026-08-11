import 'package:flutter/material.dart';

class NearbyFilterChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const NearbyFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          final isEmergency = category == 'Emergency';
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (isEmergency ? Colors.red : const Color(0xFF315E26)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(category),
              selectedColor: isEmergency ? Colors.red : const Color(0xFF315E26),
              backgroundColor: isEmergency ? Colors.red.shade50 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected 
                      ? Colors.transparent 
                      : (isEmergency ? Colors.red.shade200 : const Color(0xFF315E26).withOpacity(0.3)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
