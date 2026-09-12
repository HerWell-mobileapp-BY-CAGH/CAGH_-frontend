import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final bool isForMidwife;
  // For nearby: (distance, rating, availability)
  // For midwife: (specialization, rating, consultationType)
  final Function(String filterA, String filterB, String filterC)? onApply;

  const SearchFilterBottomSheet({
    super.key,
    this.isForMidwife = false,
    this.onApply,
  });

  @override
  State<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();

  static void show(BuildContext context, {bool isForMidwife = false, Function(String filterA, String filterB, String filterC)? onApply}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterBottomSheet(
        isForMidwife: isForMidwife,
        onApply: onApply,
      ),
    );
  }
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  // Nearby filters
  double _distance = 10.0;

  // Shared filters
  String _selectedRating = 'Any';

  // Midwife-specific filters
  String _selectedSpecialization = 'Any';
  String _selectedConsultationType = 'Any';

  // Nearby-specific filters
  String _selectedAvailability = 'Any Time';

  void _reset() {
    setState(() {
      _distance = 10.0;
      _selectedRating = 'Any';
      _selectedSpecialization = 'Any';
      _selectedConsultationType = 'Any';
      _selectedAvailability = 'Any Time';
    });
  }

  String _getLocalizedSpecialization(BuildContext context, String spec) {
    final l10n = AppLocalizations.of(context)!;
    switch (spec) {
      case 'Any': return l10n.any;
      case 'Prenatal Care': return l10n.prenatalCare;
      case 'Postnatal Care': return l10n.postnatalCare;
      case 'Labor & Delivery': return l10n.laborAndDelivery;
      case 'Family Planning': return l10n.familyPlanning;
      default: return spec;
    }
  }

  String _getLocalizedConsultationMethod(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'Any': return l10n.any;
      case 'In-Person': return l10n.inPerson;
      case 'Voice Call': return l10n.voiceCall;
      default: return type;
    }
  }

  String _getLocalizedRating(BuildContext context, String rating) {
    final l10n = AppLocalizations.of(context)!;
    switch (rating) {
      case 'Any': return l10n.any;
      case '4.5 & up': return l10n.rating45Up;
      case '4.0 & up': return l10n.rating40Up;
      case '3.5 & up': return l10n.rating35Up;
      default: return rating;
    }
  }

  String _getLocalizedAvailability(BuildContext context, String time) {
    final l10n = AppLocalizations.of(context)!;
    switch (time) {
      case 'Any Time': return l10n.anyTime;
      case 'Available Now': return l10n.availableNow;
      case 'Today': return l10n.today;
      case 'This Week': return l10n.thisWeek;
      default: return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.filters,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: Text(l10n.reset, style: const TextStyle(color: AppColors.primaryGreen)),
              )
            ],
          ),
          const SizedBox(height: 16),

          if (widget.isForMidwife) ...[
            // ── MIDWIFE FILTERS ──

            // Specialization
            Text(l10n.specialization, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Any', 'Prenatal Care', 'Postnatal Care', 'Labor & Delivery', 'Family Planning'].map((spec) {
                final isSelected = _selectedSpecialization == spec;
                return ChoiceChip(
                  label: Text(_getLocalizedSpecialization(context, spec)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedSpecialization = spec);
                  },
                  selectedColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark, fontSize: 13),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Consultation Method
            Text(l10n.consultationMethod, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Any', 'In-Person', 'Voice Call'].map((type) {
                final isSelected = _selectedConsultationType == type;
                return ChoiceChip(
                  label: Text(_getLocalizedConsultationMethod(context, type)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedConsultationType = type);
                  },
                  selectedColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Rating
            Text(l10n.rating, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Any', '4.5 & up', '4.0 & up', '3.5 & up'].map((rating) {
                final isSelected = _selectedRating == rating;
                return ChoiceChip(
                  label: Text(_getLocalizedRating(context, rating)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedRating = rating);
                  },
                  selectedColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark),
                );
              }).toList(),
            ),

          ] else ...[
            // ── NEARBY FILTERS ──

            // Distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.distance, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('${_distance.toInt()} km', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _distance,
              min: 1.0,
              max: 50.0,
              activeColor: AppColors.primaryGreen,
              inactiveColor: Colors.green.shade100,
              onChanged: (val) {
                setState(() => _distance = val);
              },
            ),
            const SizedBox(height: 20),

            // Rating
            Text(l10n.rating, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Any', '4.5 & up', '4.0 & up', '3.5 & up'].map((rating) {
                final isSelected = _selectedRating == rating;
                return ChoiceChip(
                  label: Text(_getLocalizedRating(context, rating)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedRating = rating);
                  },
                  selectedColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Availability
            Text(l10n.availability, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Any Time', 'Available Now', 'Today', 'This Week'].map((time) {
                final isSelected = _selectedAvailability == time;
                return ChoiceChip(
                  label: Text(_getLocalizedAvailability(context, time)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedAvailability = time);
                  },
                  selectedColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (widget.onApply != null) {
                  if (widget.isForMidwife) {
                    widget.onApply!(_selectedSpecialization, _selectedRating, _selectedConsultationType);
                  } else {
                    widget.onApply!(_distance.toInt().toString(), _selectedRating, _selectedAvailability);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(l10n.applyFilters, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

