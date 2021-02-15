import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:optimus/optimus.dart';
import 'package:optimus/src/progress_spinner.dart';
import 'package:optimus/src/search/dropdown_tap_interceptor.dart';
import 'package:optimus/src/search/dropdown_tile.dart';
import 'package:optimus/src/search/search_field_dropdown.dart';

class OptimusSearch<T> extends StatefulWidget {
  const OptimusSearch({
    Key key,
    this.label,
    this.placeholder,
    this.controller,
    @required this.items,
    this.isUpdating = false,
    this.isEnabled = true,
    this.isRequired = false,
    @required this.onChanged,
    this.caption,
    this.secondaryCaption,
    this.error,
    this.size = OptimusWidgetSize.large,
  }) : super(key: key);

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final List<OptimusDropdownTile<T>> items;
  final bool isUpdating;
  final bool isEnabled;
  final bool isRequired;
  final ValueSetter<T> onChanged;
  final Widget caption;
  final Widget secondaryCaption;
  final String error;
  final OptimusWidgetSize size;

  @override
  _OptimusSearchState createState() => _OptimusSearchState<T>();
}

class _OptimusSearchState<T> extends State<OptimusSearch<T>> {
  final _fieldBoxKey = GlobalKey();

  final _focusNode = FocusNode();
  OverlayEntry _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback(_afterLayoutWithShow);
      } else {
        setState(_removeOverlay);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback(_afterLayoutBuild);
  }

  @override
  void didUpdateWidget(OptimusSearch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: _handleOnBackPressed,
        child: OptimusInputField(
          controller: widget.controller,
          isRequired: widget.isRequired,
          label: widget.label,
          placeholder: widget.placeholder,
          focusNode: _focusNode,
          fieldBoxKey: _fieldBoxKey,
          suffix: widget.isUpdating
              ? const OptimusProgressSpinner()
              : const Icon(OptimusIcons.search,
                  size: 24, color: OptimusColors.neutral1000t64),
          isEnabled: widget.isEnabled,
          caption: widget.caption,
          secondaryCaption: widget.secondaryCaption,
          error: widget.error,
          size: widget.size,
        ),
      );

  void _onItemSelected() {
    _removeOverlay();
    _focusNode.unfocus();
  }

  Future<bool> _handleOnBackPressed() async {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      return false;
    }
    return true;
  }

  void _createOverlay() => _overlayEntry = _createOverlayEntry();

  void _showOverlay() {
    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry);
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry.remove();
      _overlayEntry = null;
    }
  }

  void _afterLayoutBuild(Duration d) => _createOverlay();

  void _afterLayoutWithShow(Duration d) {
    _createOverlay();
    _showOverlay();
  }

  OverlayEntry _createOverlayEntry() => OverlayEntry(
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            bool hitTest(RenderBox box) => box.hitTest(
                  BoxHitTestResult(),
                  position: box.globalToLocal(details.globalPosition),
                );

            final RenderBox inputFieldBox =
                _fieldBoxKey.currentContext.findRenderObject() as RenderBox;
            final dropdownBox = context.findRenderObject() as RenderBox;

            if (!hitTest(inputFieldBox) && !hitTest(dropdownBox)) {
              _removeOverlay();
              _focusNode.unfocus();
            }
          },
          child: DropdownTapInterceptor(
            onTap: _onItemSelected,
            child: OptimusSearchFieldDropdown(
              items: widget.items,
              anchorKey: _fieldBoxKey,
              onChanged: widget.onChanged,
            ),
          ),
        ),
      );
}