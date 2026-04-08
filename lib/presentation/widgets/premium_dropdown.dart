import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class PremiumDropdownOption<T> {
  final T value;
  final String title;
  final String? subtitle;

  const PremiumDropdownOption({
    required this.value,
    required this.title,
    this.subtitle,
  });
}

class PremiumDropdown<T> extends StatefulWidget {
  final String? labelText;
  final String placeholderText;
  final String searchHintText;
  final String emptyText;
  final T? value;
  final List<PremiumDropdownOption<T>> options;
  final ValueChanged<T>? onChanged;
  final bool enabled;
  final IconData? leadingIcon;
  final double maxMenuHeight;
  final bool showSearch;

  const PremiumDropdown({
    super.key,
    this.labelText,
    required this.placeholderText,
    required this.searchHintText,
    required this.emptyText,
    required this.options,
    required this.onChanged,
    this.value,
    this.enabled = true,
    this.leadingIcon,
    this.maxMenuHeight = 260,
    this.showSearch = false,
  });

  @override
  State<PremiumDropdown<T>> createState() => _PremiumDropdownState<T>();
}

class _PremiumDropdownState<T> extends State<PremiumDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  bool get _isInteractive => widget.enabled && widget.onChanged != null;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (!_isInteractive || _overlayEntry != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final triggerSize = renderObject.size;
    _overlayEntry = OverlayEntry(
      builder: (context) => _PremiumDropdownOverlay<T>(
        layerLink: _layerLink,
        width: triggerSize.width,
        offsetY: triggerSize.height,
        options: widget.options,
        selectedValue: widget.value,
        showSearch: widget.showSearch,
        searchHintText: widget.searchHintText,
        emptyText: widget.emptyText,
        maxMenuHeight: widget.maxMenuHeight,
        onDismiss: _closeDropdown,
        onSelected: (selected) {
          widget.onChanged?.call(selected.value);
          _closeDropdown();
        },
      ),
    );

    overlay.insert(_overlayEntry!);
    if (mounted) {
      setState(() => _isOpen = true);
    }
  }

  void _closeDropdown({bool notifyUi = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (notifyUi && mounted) {
      setState(() => _isOpen = false);
    } else {
      _isOpen = false;
    }
  }

  @override
  void dispose() {
    _closeDropdown(notifyUi: false);
    super.dispose();
  }

  PremiumDropdownOption<T>? _selectedOption() {
    final selectedValue = widget.value;
    if (selectedValue == null) return null;
    for (final option in widget.options) {
      if (option.value == selectedValue) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption();
    final hasValue = selected != null;
    final effectiveLabelColor = _isInteractive
        ? AppColors.textSecondary
        : AppColors.textHint.withValues(alpha: 0.85);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isInteractive ? _toggleDropdown : null,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isOpen
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.border.withValues(alpha: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.leadingIcon != null) ...[
                  Icon(
                    widget.leadingIcon,
                    color: effectiveLabelColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.labelText != null &&
                          widget.labelText!.isNotEmpty) ...[
                        Text(
                          widget.labelText!,
                          style: AppTypography.labelSmall.copyWith(
                            color: effectiveLabelColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        hasValue ? selected.title : widget.placeholderText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasValue
                              ? (_isInteractive
                                  ? AppColors.textPrimary
                                  : AppColors.textHint)
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: _isOpen ? AppColors.primary : effectiveLabelColor,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumDropdownOverlay<T> extends StatefulWidget {
  final LayerLink layerLink;
  final double width;
  final double offsetY;
  final List<PremiumDropdownOption<T>> options;
  final T? selectedValue;
  final bool showSearch;
  final String searchHintText;
  final String emptyText;
  final double maxMenuHeight;
  final VoidCallback onDismiss;
  final ValueChanged<PremiumDropdownOption<T>> onSelected;

  const _PremiumDropdownOverlay({
    required this.layerLink,
    required this.width,
    required this.offsetY,
    required this.options,
    required this.selectedValue,
    required this.showSearch,
    required this.searchHintText,
    required this.emptyText,
    required this.maxMenuHeight,
    required this.onDismiss,
    required this.onSelected,
  });

  @override
  State<_PremiumDropdownOverlay<T>> createState() =>
      _PremiumDropdownOverlayState<T>();
}

class _PremiumDropdownOverlayState<T>
    extends State<_PremiumDropdownOverlay<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late List<PremiumDropdownOption<T>> _filteredOptions;

  @override
  void initState() {
    super.initState();
    _filteredOptions = List<PremiumDropdownOption<T>>.from(widget.options);
    if (widget.showSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _PremiumDropdownOverlay<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showSearch) {
      _filteredOptions = List<PremiumDropdownOption<T>>.from(widget.options);
      return;
    }
    if (oldWidget.options != widget.options ||
        oldWidget.showSearch != widget.showSearch) {
      _applyFilter(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _applyFilter(String query) {
    if (!widget.showSearch) {
      setState(() {
        _filteredOptions = List<PremiumDropdownOption<T>>.from(widget.options);
      });
      return;
    }
    final normalized = query.trim().toLowerCase();
    setState(() {
      if (normalized.isEmpty) {
        _filteredOptions = List<PremiumDropdownOption<T>>.from(widget.options);
      } else {
        _filteredOptions = widget.options.where((option) {
          final title = option.title.toLowerCase();
          final subtitle = option.subtitle?.toLowerCase() ?? '';
          return title.contains(normalized) || subtitle.contains(normalized);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onDismiss,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: widget.layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, widget.offsetY),
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  color: Colors.transparent,
                  child: Focus(
                    autofocus: true,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.escape) {
                        widget.onDismiss();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0.96, end: 1),
                      builder: (context, scale, child) {
                        final safeOpacity =
                            ((scale - 0.96) / 0.04).clamp(0.0, 1.0).toDouble();
                        return Opacity(
                          opacity: safeOpacity,
                          child: Transform.scale(scale: scale, child: child),
                        );
                      },
                      child: Container(
                        width: widget.width,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.16),
                              blurRadius: 26,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.showSearch) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background
                                      .withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: _applyFilter,
                                  style: AppTypography.bodyMedium,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: widget.searchHintText,
                                    hintStyle:
                                        AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 22,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                            ],
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: widget.maxMenuHeight,
                              ),
                              child: _filteredOptions.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        widget.emptyText,
                                        textAlign: TextAlign.center,
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: _filteredOptions.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 4),
                                      itemBuilder: (context, index) {
                                        final option = _filteredOptions[index];
                                        final isActive = option.value ==
                                            widget.selectedValue;

                                        return Material(
                                          color: isActive
                                              ? AppColors.primary
                                                  .withValues(alpha: 0.12)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            onTap: () =>
                                                widget.onSelected(option),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          option.title,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: AppTypography
                                                              .bodyMedium
                                                              .copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: isActive
                                                                ? AppColors
                                                                    .primary
                                                                : AppColors
                                                                    .textPrimary,
                                                          ),
                                                        ),
                                                        if ((option.subtitle ??
                                                                '')
                                                            .trim()
                                                            .isNotEmpty) ...[
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            option.subtitle!,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: AppTypography
                                                                .labelSmall
                                                                .copyWith(
                                                              color: AppColors
                                                                  .textSecondary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  AnimatedOpacity(
                                                    opacity: isActive ? 1 : 0,
                                                    duration: const Duration(
                                                        milliseconds: 180),
                                                    child: const Icon(
                                                      Icons.check_rounded,
                                                      size: 18,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
