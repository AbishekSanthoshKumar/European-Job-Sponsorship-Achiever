import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Labelled text field with consistent spacing.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.required = false,
  });

  final String label;
  final String? hint;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        ],
      ],
    );
  }
}

/// Dropdown styled to match the input theme.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.hint,
    this.isDense = false,
  });

  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      isDense: isDense,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: isDense ? Insets.sm : Insets.md,
        ),
      ),
      icon: const Icon(Icons.expand_more_rounded, size: 18),
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item,
            child: Text(
              labelBuilder(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// A row of selectable chips backed by an enum or list of values.
class ChipSelector<T> extends StatelessWidget {
  const ChipSelector({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.colorBuilder,
    this.wrap = true,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelBuilder;
  final Color Function(T)? colorBuilder;
  final ValueChanged<T> onSelected;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = [
      for (final v in values)
        Builder(builder: (context) {
          final isSelected = v == selected;
          final color = colorBuilder?.call(v) ?? theme.colorScheme.primary;
          return InkWell(
            onTap: () => onSelected(v),
            borderRadius: BorderRadius.circular(Corners.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Insets.md, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(Corners.sm),
                border: Border.all(
                  color: isSelected ? color : theme.colorScheme.outline,
                  width: isSelected ? 1.4 : 1,
                ),
              ),
              child: Text(
                labelBuilder(v),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
    ];

    if (!wrap) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final c in chips)
              Padding(
                padding: const EdgeInsets.only(right: Insets.sm),
                child: c,
              ),
          ],
        ),
      );
    }
    return Wrap(spacing: Insets.sm, runSpacing: Insets.sm, children: chips);
  }
}

/// 0-10 slider used for the manual opportunity ratings.
class RatingSlider extends StatelessWidget {
  const RatingSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.color,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return Row(
      children: [
        SizedBox(
          width: 128,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: accent,
              thumbColor: accent,
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: AppTheme.mono(
              size: 13,
              weight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
      ],
    );
  }
}

/// Collapsible section used for progressive disclosure in long forms.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final IconData? icon;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(Corners.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.sm),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon,
                      size: 15, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Insets.sm),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.expand_more_rounded,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: Insets.sm, bottom: Insets.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}

/// Date picker rendered as a tappable field.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Select date',
    this.firstDate,
    this.lastDate,
    this.clearable = true,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool clearable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final has = value != null;

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate ?? DateTime(now.year - 3),
          lastDate: lastDate ?? DateTime(now.year + 5),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(Corners.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.md, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Corners.md),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                has ? _fmt(value!) : placeholder,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: has
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (has && clearable)
              InkWell(
                onTap: () => onChanged(null),
                borderRadius: BorderRadius.circular(Corners.pill),
                child: Icon(Icons.close_rounded,
                    size: 15, color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} '
      '${const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][d.month - 1]} ${d.year}';
}
