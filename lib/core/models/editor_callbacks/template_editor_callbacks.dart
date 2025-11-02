// Project imports:
import '/core/models/editor_callbacks/standalone_editor_callbacks.dart';
import '/features/main_editor/main_editor.dart';
import '../layers/layer.dart';

/// A class representing callbacks for the template editor.
class TemplateEditorCallbacks extends StandaloneEditorCallbacks {
  /// Creates a new instance of [TemplateEditorCallbacks].
  const TemplateEditorCallbacks({
    this.onSearchChanged,
    this.onTapEditTemplate,
    super.onInit,
    super.onAfterViewInit,
  });

  /// A callback function that is triggered when a template is tapped for
  /// editing.
  ///
  /// This function is called with the current editor state, the template data,
  /// and the index of the template within the list of layers. It allows the
  /// implementation to define custom behavior when a user taps on a template
  /// to initiate editing, such as opening a template editing interface or
  /// displaying additional options.
  ///
  /// The callback is optional and can be set to `null` if no action is
  /// required when a template is tapped.
  ///
  /// Parameters:
  /// - [editorState]: The current state of the image editor, providing access
  ///   to relevant editor properties and methods for modifying the editing
  ///   environment.
  /// - [template]: The `WidgetLayer` instance representing the template
  ///   that was tapped. This includes the template's properties such as its
  ///   widget, position, rotation, scale, and more.
  /// - [index]: The index of the template in the list of active layers, which
  ///   can be used to identify and manipulate the specific template layer.
  ///
  /// Example usage:
  /// ```dart
  /// onTapEditTemplate: (editorState, template, index) {
  ///   // Implement custom editing logic here
  ///   state.replaceLayer(
  ///     index: index,
  ///     layer: template.copyWith(
  ///       template: Template(
  ///         index: newIndex,
  ///       ),
  ///     ),
  ///   );
  /// },
  /// ```
  final Function(ProImageEditorState editorState, WidgetLayer template)?
      onTapEditTemplate;

  /// A callback triggered each time the search value changes.
  ///
  /// This callback is activated exclusively when the editor mode is set to
  /// 'WhatsApp'.
  final Function(String value)? onSearchChanged;

  /// Creates a copy with modified editor callbacks.
  TemplateEditorCallbacks copyWith({
    Function(ProImageEditorState editorState, WidgetLayer template)?
        onTapEditTemplate,
    Function(String value)? onSearchChanged,
    Function()? onInit,
    Function()? onAfterViewInit,
  }) {
    return TemplateEditorCallbacks(
      onInit: onInit ?? this.onInit,
      onAfterViewInit: onAfterViewInit ?? this.onAfterViewInit,
      onTapEditTemplate: onTapEditTemplate ?? this.onTapEditTemplate,
      onSearchChanged: onSearchChanged ?? this.onSearchChanged,
    );
  }
}
