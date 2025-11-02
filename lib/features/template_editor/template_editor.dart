import 'package:flutter/material.dart';

import '/core/mixins/converted_configs.dart';
import '/core/mixins/editor_configs_mixin.dart';
import '/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/layers/layer.dart';
import '/shared/widgets/extended/extended_pop_scope.dart';

/// The `TemplateEditor` class is responsible for creating a widget that allows
/// users to select templates
class TemplateEditor extends StatefulWidget with SimpleConfigsAccess {
  /// Creates an `TemplateEditor` widget.
  const TemplateEditor({
    super.key,
    required this.configs,
    this.callbacks = const ProImageEditorCallbacks(),
    required this.scrollController,
  });
  @override
  final ProImageEditorConfigs configs;

  @override
  final ProImageEditorCallbacks callbacks;

  /// Controller for managing scroll actions.
  final ScrollController scrollController;

  @override
  createState() => TemplateEditorState();
}

/// The state class for the `TemplateEditor` widget.
class TemplateEditorState extends State<TemplateEditor>
    with ImageEditorConvertedConfigs, SimpleConfigsAccessState {
  /// Closes the editor without applying changes.
  void close() {
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    callbacks.templateEditorCallbacks?.onInit?.call();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      callbacks.templateEditorCallbacks?.onAfterViewInit?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(
      templateEditorConfigs.builder != null,
      '`builder` is required',
    );

    return ExtendedPopScope(
      canPop: templateEditorConfigs.enableGesturePop,
      child: templateEditorConfigs.builder!.call(
        setLayer,
        widget.scrollController,
      ),
    );
  }

  /// Close the editor with the selected widget-layer.
  void setLayer(WidgetLayer widgetLayer) {
    Navigator.of(context).pop(widgetLayer);
  }
}
