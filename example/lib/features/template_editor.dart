// Dart imports:
import 'dart:io';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '/features/stickers_example.dart';

// Project imports:
import '/core/mixin/example_helper.dart';

/// Template editor for creating custom templates
class TemplateEditor extends StatefulWidget {
  /// Creates a new [TemplateEditor] widget.
  const TemplateEditor({super.key});

  @override
  State<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<TemplateEditor>
    with ExampleHelperState<TemplateEditor> {
  bool _ignorePlatformIssue = false;
  bool _templateCreated = false;

  @override
  void initState() {
    super.initState();
    _initTemplate();
  }

  Future<void> _initTemplate() async {
    setState(() {
      _templateCreated = true;
    });
    preCacheImage(assetPath: 'assets/black.png');
  }

  Future<String> _getTemplatesDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final templatesDir = Directory('${directory.path}/templates');
    if (!await templatesDir.exists()) {
      await templatesDir.create(recursive: true);
    }
    return templatesDir.path;
  }

  Future<void> _saveTemplate() async {
    try {
      print('saveTemplate');
      final editor = editorKey.currentState;
      if (editor == null) return;

      final history = await editor.exportStateHistory(
        configs: const ExportEditorConfigs(
          historySpan: ExportHistorySpan.current,
          maxDecimalPlaces: 3,
        ),
      );

      print('history: $history');

      final templatesDir = await _getTemplatesDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'template_$timestamp.json';
      final filePath = '$templatesDir/$filename';

      await history.toFile(path: filePath);
      print('filePath: $filePath');
      if (!mounted) return;
      print('mounted');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('템플릿 저장됨: $filename')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  Future<void> _loadTemplate() async {
    try {
      final templatesDir = await _getTemplatesDirectory();
      final dir = Directory(templatesDir);
      final files = await dir
          .list()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장된 템플릿이 없습니다')),
        );
        return;
      }

      if (!mounted) return;
      final selectedFile = await showDialog<String>(
        context: context,
        builder: (context) => _buildTemplateListDialog(files),
      );

      if (selectedFile == null || !mounted) return;

      // Read JSON file
      final file = File(selectedFile);
      final jsonString = await file.readAsString();
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      final history = ImportStateHistory.fromMap(
        jsonMap,
        configs: const ImportEditorConfigs(
          recalculateSizeAndPosition: true,
        ),
      );

      // Reload editor with new history
      setState(() {
        _loadedHistory = history;
        _templateCreated = false; // Force rebuild
      });

      // Wait for rebuild
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      setState(() {
        _templateCreated = true; // Rebuild with new history
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('템플릿 로드됨')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로드 실패: $e')),
      );
    }
  }

  Future<void> _loadTemplate2() async {
    try {
      final templatesDir = await _getTemplatesDirectory();
      final dir = Directory(templatesDir);
      final files = await dir
          .list()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장된 템플릿이 없습니다')),
        );
        return;
      }

      if (!mounted) return;
      final selectedFile = await showDialog<String>(
        context: context,
        builder: (context) => _buildTemplateListDialog(files),
      );

      if (selectedFile == null || !mounted) return;

      // Read and print JSON file
      final file = File(selectedFile);
      final jsonString = await file.readAsString();
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      print('=== 선택된 템플릿 파일 ===');
      print('파일 경로: $selectedFile');
      print('파일명: ${selectedFile.split('/').last.split('\\').last}');
      print('\n=== JSON 내용 ===');
      print(const JsonEncoder.withIndent('  ').convert(jsonMap));
      print('\n=== 레이어 정보 ===');

      if (jsonMap.containsKey('layers')) {
        final layers = jsonMap['layers'] as List;
        print('총 레이어 개수: ${layers.length}');
        for (int i = 0; i < layers.length; i++) {
          final layer = layers[i] as Map<String, dynamic>;
          print('\n레이어 $i:');
          print('  타입: ${layer['type']}');
          if (layer.containsKey('text')) {
            print('  텍스트: ${layer['text']}');
          }
          if (layer.containsKey('offset')) {
            print('  위치: ${layer['offset']}');
          }
          if (layer.containsKey('scale')) {
            print('  크기: ${layer['scale']}');
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '템플릿 로드 완료: ${selectedFile.split('/').last.split('\\').last}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('=== 로드 실패 ===');
      print('에러: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로드 실패: $e')),
      );
    }
  }

  Widget _buildTemplateListDialog(List<FileSystemEntity> files) {
    return AlertDialog(
      title: const Text('템플릿 선택'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final filename = file.path.split('/').last.split('\\').last;
            final timestamp =
                filename.replaceAll('template_', '').replaceAll('.json', '');

            return ListTile(
              leading: const Icon(Icons.layers),
              title: Text(filename),
              subtitle: Text('생성일: ${_formatTimestamp(timestamp)}'),
              onTap: () => Navigator.pop(context, file.path),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateFormat('yyyyMMdd_HHmmss').parse(timestamp);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  ImportStateHistory? _loadedHistory;

  ReactiveWidget _buildSaveButton(Stream<void> rebuildStream) {
    return ReactiveWidget(
      stream: rebuildStream,
      builder: (_) {
        return Positioned(
          top: 60,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'save_template_button',
            onPressed: _saveTemplate,
            backgroundColor: Colors.blue,
            child: const Icon(
              Icons.save,
              color: Colors.white,
            ),
            tooltip: '템플릿 저장',
          ),
        );
      },
    );
  }

  ReactiveWidget _buildLoadButton(Stream<void> rebuildStream) {
    return ReactiveWidget(
      stream: rebuildStream,
      builder: (_) {
        return Positioned(
          top: 130,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'load_template_button',
            onPressed: _loadTemplate,
            backgroundColor: Colors.green,
            child: const Icon(
              Icons.folder_open,
              color: Colors.white,
            ),
            tooltip: '템플릿 로드',
          ),
        );
      },
    );
  }

  ReactiveWidget _buildLoadButton2(Stream<void> rebuildStream) {
    return ReactiveWidget(
      stream: rebuildStream,
      builder: (_) {
        return Positioned(
          top: 200,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'load_template_button_2',
            onPressed: _loadTemplate2,
            backgroundColor: Colors.orange,
            child: const Icon(
              Icons.folder_special,
              color: Colors.white,
            ),
            tooltip: '템플릿 로드 2',
          ),
        );
      },
    );
  }

  Widget buildStickers(
    void Function(WidgetLayer widget) setLayer,
    ScrollController scrollController,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 80,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        controller: scrollController,
        itemCount: 21,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              // Important make sure the image is completely loaded
              // cuz the editor will directly take a screenshot
              // inside of a background isolated thread.
              LoadingDialog.instance.show(
                context,
                configs: const ProImageEditorConfigs(),
                theme: Theme.of(context),
              );
              await precacheImage(
                NetworkImage(
                  'https://picsum.photos/id/${(index + 3) * 3}/2000',
                ),
                context,
              );
              LoadingDialog.instance.hide();
              setLayer(
                WidgetLayer(
                  widget: Sticker(index: index),

                  /// The `exportConfigs` parameter is optional but
                  /// useful if you want to import or export history and
                  /// directly load the same sticker.
                  ///
                  /// If `exportConfigs` is not added, the editor will
                  /// convert the exported state history to a `Uint8List`
                  /// to restore the layer. However, this may reduce
                  /// quality and cause a delay during export.
                  ///
                  /// If you use the ID parameter, it is important to set
                  /// up a `widgetLoader` inside the `ImportEditorConfigs`
                  ///  when importing the state history.
                  /// Refer to the [import-example](https://github.com/hm21/pro_image_editor/blob/stable/example/lib/features/import_export_example.dart)
                  /// for details on how this works.
                  exportConfigs: WidgetLayerExportConfigs(
                    id: 'sticker-$index',

                    /// Alternatively, you can use one of the parameters
                    /// listed below instead of the id, which does not
                    /// require setting up the widgetLoader. However,
                    /// please note that for complex widgets, this
                    /// approach may slightly alter their size.
                    ///
                    /// networkUrl: '',
                    /// assetPath: '',
                    /// fileUrl: '',
                  ),
                ),
              );
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Sticker(index: index),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_templateCreated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!kIsWeb && Platform.isWindows && !_ignorePlatformIssue) {
      return Scaffold(
        appBar: AppBar(),
        body: Column(
          spacing: 16,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _ignorePlatformIssue = true;
                });
              },
              child: const Text('Ignore Error'),
            ),
            Expanded(
              child: ErrorWidget(
                'Windows didn\'t support "GoogleFonts.notoColorEmoji"',
              ),
            ),
          ],
        ),
      );
    } else if (!isPreCached) {
      return const PrepareImageWidget();
    }

    return ProImageEditor.asset(
      'assets/black.png',
      key: editorKey,
      callbacks: ProImageEditorCallbacks(
        onImageEditingStarted: onImageEditingStarted,
        onImageEditingComplete: onImageEditingComplete,
        onCloseEditor: (editorMode) => onCloseEditor(
          editorMode: editorMode,
          enablePop: !isDesktopMode(context),
        ),
        mainEditorCallbacks: MainEditorCallbacks(
          helperLines: HelperLinesCallbacks(onLineHit: vibrateLineHit),
        ),
      ),
      configs: ProImageEditorConfigs(
        designMode: platformDesignMode,
        mainEditor: MainEditorConfigs(
          enableCloseButton: !isDesktopMode(context),
          widgets: MainEditorWidgets(
            bodyItems: (editor, rebuildStream) {
              return [
                _buildSaveButton(rebuildStream),
                _buildLoadButton(rebuildStream),
                _buildLoadButton2(rebuildStream),
              ];
            },
          ),
        ),
        stateHistory: StateHistoryConfigs(
          initStateHistory: _loadedHistory,
        ),
        textEditor: TextEditorConfigs(
          showSelectFontStyleBottomBar: true,
          customTextStyles: [
            GoogleFonts.roboto(),
            GoogleFonts.averiaLibre(),
            GoogleFonts.lato(),
            GoogleFonts.comicNeue(),
            GoogleFonts.actor(),
            GoogleFonts.odorMeanChey(),
            GoogleFonts.nabla(),
          ],
        ),
        emojiEditor: EmojiEditorConfigs(
          enabled: false,
        ),
        stickerEditor: StickerEditorConfigs(
          enabled: true,
          builder: (setLayer, scrollController) {
            return buildStickers(setLayer, scrollController);
          },
        ),
        filterEditor: FilterEditorConfigs(
          enabled: false,
        ),
        blurEditor: BlurEditorConfigs(
          enabled: false,
        ),
        cropRotateEditor: CropRotateEditorConfigs(
          enabled: false,
        ),
        paintEditor: PaintEditorConfigs(
          enabled: false,
        ),
        tuneEditor: TuneEditorConfigs(
          enabled: false,
        ),
      ),
    );
  }
}
