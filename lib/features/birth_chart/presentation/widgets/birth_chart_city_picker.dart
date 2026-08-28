/// Modal city list for birth location.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/birth_chart_copy.dart';
import '../../data/birth_chart_cities.dart';

Future<BirthChartCity?> showBirthChartCityPicker(
  BuildContext context, {
  BirthChartCity? selected,
}) {
  return showModalBottomSheet<BirthChartCity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    builder: (context) => BirthChartCityPickerSheet(selected: selected),
  );
}

class BirthChartCityPickerSheet extends StatefulWidget {
  const BirthChartCityPickerSheet({super.key, this.selected});

  final BirthChartCity? selected;

  @override
  State<BirthChartCityPickerSheet> createState() =>
      _BirthChartCityPickerSheetState();
}

class _BirthChartCityPickerSheetState extends State<BirthChartCityPickerSheet> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final cities = BirthChartCities.search(_query);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: TextField(
                  autofocus: true,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: BirthChartCopy.searchCity,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.gold.withValues(alpha: 0.7),
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: AppLayout.contentBottomBreath,
                  ),
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final active = city.id == widget.selected?.id;
                    return ListTile(
                      title: Text(
                        city.label(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: active
                              ? AppColors.goldLight
                              : AppColors.textPrimary,
                        ),
                      ),
                      trailing: active
                          ? Icon(Icons.check_rounded, color: AppColors.gold)
                          : null,
                      onTap: () => Navigator.of(context).pop(city),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
