import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/core/models/editor_configs/template_editor_configs.dart';
import '/core/models/layers/template_layer.dart';

/// A custom widget item representing a layer in the sticker editor.
class LayerWidgetTemplateItem extends StatelessWidget {
  /// Creates a [LayerWidgetCustomItem] with the given layer and editor
  /// configurations.
  const LayerWidgetTemplateItem({
    super.key,
    required this.layer,
    required this.templateEditorConfigs,
  });

  /// The widget layer that this item represents.
  final TemplateLayer layer;

  /// Configuration settings for the sticker editor.
  final TemplateEditorConfigs templateEditorConfigs;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: layer.scale,
      alignment: Alignment.center,
      child: Container(
        width: (layer.width ?? templateEditorConfigs.initWidth),
        height: (layer.height ?? templateEditorConfigs.initHeight),
        child: layer.widget,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    layer.debugFillProperties(properties);
  }
}
