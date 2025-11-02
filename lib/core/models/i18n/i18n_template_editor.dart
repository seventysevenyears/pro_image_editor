/// Internationalization (i18n) settings for the I18nTemplateEditor Editor
/// component.
class I18nTemplateEditor {
  /// Creates an instance of [I18nTemplateEditor] with customizable
  /// internationalization settings.
  ///
  /// You can provide translations and messages specifically for the
  /// I18nTemplateEditor Editor
  /// component of your application.
  ///
  /// Example:
  ///
  /// ```dart
  /// I18nTemplateEditor(
  ///   bottomNavigationBarText: 'I18nTemplateEditor',
  /// )
  /// ```
  const I18nTemplateEditor({
    this.bottomNavigationBarText = 'Template',
  });

  /// Text for the bottom navigation bar item that opens the I18nTemplateEditor
  /// Editor.
  final String bottomNavigationBarText;
}
