// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '/pro_image_editor.dart';
import '../../frosted_glass/frosted_glass.dart';

/// A widget that provides the sticker editor interface in the ProImageEditor.
///
/// The [GroundedTemplateEditor] allows users to browse and apply templates to an
/// image. It includes a search bar for filtering stickers and integrates with
/// [TemplateEditor] for template manipulation. The widget uses
/// [ProImageEditorConfigs] for configuration and [ProImageEditorCallbacks] for
/// handling user actions.
class GroundedTemplateEditor extends StatefulWidget {
  /// Constructor for the [GroundedTemplateEditor].
  ///
  /// Requires [configs] and [callbacks] to manage the state and interaction of
  /// the template editor.
  const GroundedTemplateEditor({
    super.key,
    required this.configs,
    required this.callbacks,
  });

  /// The configuration for the image editor.
  final ProImageEditorConfigs configs;

  /// The callbacks from the image editor.
  final ProImageEditorCallbacks callbacks;

  @override
  State<GroundedTemplateEditor> createState() => _GroundedTemplateEditorState();
}

/// State class for [GroundedTemplateEditor].
///
/// This state manages the template editor, including the template search
/// functionality and interactions with the [TemplateEditor] widget. It handles
/// toggling of the search mode and provides a user interface for selecting and
/// applying templates.
class _GroundedTemplateEditorState extends State<GroundedTemplateEditor> {
  final _templateScrollController = ScrollController();
  bool _activeSearch = false;
  late TextEditingController _searchCtrl;
  late FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchFocus = FocusNode();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _templateScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color foreGroundColor = widget.configs.mainEditor.style.appBarColor;
    return FrostedGlassEffect(
      radius: BorderRadius.zero,
      child: Scaffold(
        backgroundColor: Colors.black38,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 7),
              Expanded(
                child: TemplateEditor(
                  configs: widget.configs,
                  scrollController: _templateScrollController,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
                color: const Color(0xFF222222),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: widget.configs.i18n.cancel,
                      onPressed: () {
                        if (_activeSearch) {
                          setState(() {
                            _searchCtrl.clear();
                            _activeSearch = false;
                            widget.callbacks.templateEditorCallbacks
                                ?.onSearchChanged
                                ?.call('');
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(
                        widget.configs.mainEditor.icons.closeEditor,
                        color: foreGroundColor,
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _activeSearch
                            ? _buildSearchBar()
                            : Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _activeSearch = !_activeSearch;
                                    });
                                  },
                                  icon: const Icon(Icons.search),
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the search bar for filtering stickers.
  ///
  /// Depending on the design mode specified in [ProImageEditorConfigs], either
  /// a Cupertino-style or Material-style search bar is displayed.
  Widget _buildSearchBar() {
    if (widget.configs.designMode == ImageEditorDesignMode.cupertino) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  autofocus: true,
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: (value) {
                    widget.callbacks.templateEditorCallbacks?.onSearchChanged
                        ?.call(value);
                    _searchFocus.requestFocus();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _searchFocus.requestFocus();
                    });
                  },
                  itemColor: const Color.fromARGB(255, 243, 243, 243),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              CupertinoButton(
                child: Text(widget.configs.i18n.cancel),
                onPressed: () {
                  setState(() {
                    _activeSearch = false;
                  });
                },
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: TextField(
                  autofocus: true,
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: (value) {
                    widget.callbacks.templateEditorCallbacks?.onSearchChanged
                        ?.call(value);
                    _searchFocus.requestFocus();
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.configs.i18n.emojiEditor.search,
                    isCollapsed: true,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  if (_searchCtrl.text.isNotEmpty) {
                    _searchCtrl.clear();
                    widget.callbacks.templateEditorCallbacks?.onSearchChanged
                        ?.call('');
                  } else {
                    _activeSearch = false;
                  }
                });
              },
            ),
          ],
        ),
      );
    }
  }
}
