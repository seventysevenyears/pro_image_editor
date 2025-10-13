import 'package:flutter/widgets.dart';

import '/core/models/layers/layer.dart';
import '../icons/template_editor_icons.dart';
import '../styles/template_editor_style.dart';
import 'utils/base_editor_layer_configs.dart';
import 'utils/base_sub_editor_configs.dart';

/// Configuration options for a template editor.
///
/// `TemplateEditorConfigs` allows you to define various settings for a templ ate
/// editor. You can configure features like enabling/disabling the editor,
/// initial template width, and a custom method to build templates.
///
/// Example usage:
/// ```dart
/// TemplateEditorConfigs(
///   enabled: false,
///   initWidth: 150,
///   buildTemplates: (setLayer) {
///     return Container(); // Replace with your builder to load and display templates.
///   },
/// );
/// ```
class TemplateEditorConfigs
    implements BaseEditorLayerConfigs, BaseSubEditorConfigs {
  /// Creates an instance of TemplateEditorConfigs with optional settings.
  ///
  /// By default, the editor is disabled (if not specified), and other
  /// properties are set to reasonable defaults.
  const TemplateEditorConfigs({
    this.layerFractionalOffset = const Offset(-0.5, -0.5),
    this.enableGesturePop = true,
    this.builder,
    this.initWidth = 100,
    this.initHeight = 100,
    this.minScale = double.negativeInfinity,
    this.maxScale = double.infinity,
    this.enabled = false,
    this.style = const TemplateEditorStyle(),
    this.icons = const TemplateEditorIcons(),
  })  : assert(initWidth > 0, 'initWidth must be positive'),
        assert(maxScale >= minScale,
            'maxScale must be greater than or equal to minScale');

  /// {@macro layerFractionalOffset}
  @override
  final Offset layerFractionalOffset;

  /// {@macro enableGesturePop}
  @override
  final bool enableGesturePop;

  /// Indicates whether the template editor is enabled.
  ///
  /// When set to `true`, the template editor is active and users can interact
  /// with it.
  /// If `false`, the editor is disabled and does not respond to user inputs.
  final bool enabled;

  /// The initial width of the templates in the editor.
  ///
  /// Specifies the starting width of the templates when they are first placed
  /// in the editor. This value is in logical pixels.
  final double initWidth;

  /// The initial height of the templates in the editor.
  ///
  /// Specifies the starting height of the templates when they are first placed
  /// in the editor. This value is in logical pixels.
  final double initHeight;

  /// A callback that builds the templates.
  ///
  /// This typedef is a function that takes a function as a parameter and
  /// returns a Widget. The function parameter `setLayer` is used to set a
  /// layer in the editor. This callback allows for customizing the appearance
  /// and behavior of templates in the editor.
  final TemplateBuilder? builder;

  /// The minimum scale factor from the layer.
  final double minScale;

  /// The maximum scale factor from the layer.
  final double maxScale;

  /// Style configuration for the template editor.
  final TemplateEditorStyle style;

  /// Icons used in the template editor.
  final TemplateEditorIcons icons;

  /// Creates a copy of this `TemplateEditorConfigs` object with the given fields
  /// replaced with new values.
  ///
  /// The [copyWith] method allows you to create a new instance of
  /// [TemplateEditorConfigs] with some properties updated while keeping the
  /// others unchanged.
  TemplateEditorConfigs copyWith({
    Offset? layerFractionalOffset,
    bool? enableGesturePop,
    bool? enabled,
    double? initWidth,
    double? initHeight,
    TemplateBuilder? builder,
    double? minScale,
    double? maxScale,
    TemplateEditorStyle? style,
    TemplateEditorIcons? icons,
  }) {
    return TemplateEditorConfigs(
      layerFractionalOffset:
          layerFractionalOffset ?? this.layerFractionalOffset,
      enableGesturePop: enableGesturePop ?? this.enableGesturePop,
      enabled: enabled ?? this.enabled,
      initWidth: initWidth ?? this.initWidth,
      initHeight: initHeight ?? this.initHeight,
      builder: builder ?? this.builder,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      style: style ?? this.style,
      icons: icons ?? this.icons,
    );
  }
}

/// A typedef representing a function signature for building sticker widgets.
///
/// This typedef defines a function that builds a widget for templates in an
/// editor, allowing customization of how stickers are displayed and
/// manipulated within the user interface.
typedef BuildTemplate = Widget Function(
  Function(
    Widget widget, {
    WidgetLayerExportConfigs? exportConfigs,
  }) setLayer,
  ScrollController scrollController,
);

/// A typedef representing a function signature for building sticker widgets.
///
/// This typedef defines a function that builds a widget for stickers in an
/// editor, allowing customization of how stickers are displayed and
/// manipulated within the user interface.
typedef TemplateBuilder = Widget Function(
  Function(WidgetLayer widgetLayer) setLayer,
  ScrollController scrollController,
);
