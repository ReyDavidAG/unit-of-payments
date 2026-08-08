import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../config/theme/app_spacing.dart';
import '../subscriptions/sheet_drag_handle_widget.dart';

/// Bottom-sheet date picker built on [TableCalendar]. Replaces the stock
/// Material `showDatePicker`, whose M3 layout (oversized header, edit
/// affordance, full-bleed day grid) reads off-brand against this app.
///
/// Tapping a day selects it visually; tapping **Aceptar** returns the date.
/// Returning null means the user dismissed.
class CustomDatePicker extends StatefulWidget {
  const CustomDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    super.key,
  });

  /// The day the picker opens on. Past dates are the norm here: most
  /// subscriptions started before the app did.
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) => showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CustomDatePicker(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  void _confirm() => Navigator.of(context).pop(_selectedDay);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.xs,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetDragHandleWidget(),
          Text('Selecciona una fecha', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.md),
          TableCalendar<DateTime>(
            firstDay: widget.firstDate,
            lastDay: widget.lastDate,
            focusedDay: _focusedDay,
            locale: 'es_MX',
            rowHeight: 44,
            daysOfWeekHeight: 24,
            availableGestures: AvailableGestures.horizontalSwipe,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            }),
            onPageChanged: (focused) => _focusedDay = focused,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: const Icon(Icons.chevron_left),
              rightChevronIcon: const Icon(Icons.chevron_right),
              titleTextStyle: theme.textTheme.titleMedium ?? const TextStyle(),
              leftChevronMargin: EdgeInsets.zero,
              rightChevronMargin: EdgeInsets.zero,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              weekendStyle: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(AppSpacing.xs2),
              defaultTextStyle: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
              weekendTextStyle: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              todayTextStyle: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            calendarBuilders: CalendarBuilders<DateTime>(
              disabledBuilder: (context, day, _) => Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _confirm,
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
