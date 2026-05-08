// Dart imports:
import 'dart:io';
import 'dart:convert';
import 'dart:math';

// Flutter imports:
import 'package:align_positioned/align_positioned.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:pro_image_editor/features/text_editor/widgets/rounded_background_text/rounded_background_text.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '/features/stickers_example.dart';

// Project imports:
import '/core/mixin/example_helper.dart';

/// Template editor for creating custom templates
class TemplateExample extends StatefulWidget {
  /// Creates a new [TemplateExample] widget.
  const TemplateExample({super.key});

  @override
  State<TemplateExample> createState() => _TemplateExampleState();
}

class _TemplateExampleState extends State<TemplateExample>
    with ExampleHelperState<TemplateExample> {
  bool _ignorePlatformIssue = false;
  bool _templateCreated = false;
  TextEditorConfigs textEditorConfigs = TextEditorConfigs();
  TemplateEditorConfigs templateEditorConfigs = TemplateEditorConfigs();
  ImportStateHistory? _loadedHistory;

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
    templateEditorConfigs = TemplateEditorConfigs(
      enabled: true,
    );
    textEditorConfigs = TextEditorConfigs(
      showSelectFontStyleBottomBar: true,
      // customTextStyles: [
      //   GoogleFonts.roboto(),
      //   GoogleFonts.averiaLibre(),
      //   GoogleFonts.lato(),
      //   GoogleFonts.comicNeue(),
      //   GoogleFonts.actor(),
      //   GoogleFonts.odorMeanChey(),
      //   GoogleFonts.nabla(),
      // ],
    );
  }

  Future<Directory> _getBaseDownloadsDirectory() async {
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          const androidDownloads = '/storage/emulated/0/Download';
          final dir = Directory(androidDownloads);
          if (await dir.exists()) {
            return dir;
          }
        } else if (Platform.isWindows ||
            Platform.isMacOS ||
            Platform.isLinux) {
          final dir = await getDownloadsDirectory();
          if (dir != null) {
            return dir;
          }
        }
      } catch (e) {
        print('Downloads 디렉토리 가져오기 실패, 기본 경로로 fallback: $e');
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<String> _getTemplatesDirectory() async {
    final directory = await _getBaseDownloadsDirectory();
    final templatesDir = Directory('${directory.path}/pro_image_editor/templates');
    if (!await templatesDir.exists()) {
      await templatesDir.create(recursive: true);
    }
    return templatesDir.path;
  }

  Future<String> _getLayerExportsDirectory() async {
    final directory = await _getBaseDownloadsDirectory();
    final exportsDir = Directory('${directory.path}/pro_image_editor/layer_exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    return exportsDir.path;
  }

  /// JSON 템플릿을 수정하는 함수
  /// references의 모든 내용을 새로운 "A" 위젯의 meta에 복사
  Map<String, dynamic>? _modifyTemplateJson(Map<String, dynamic> jsonMap) {
    try {
      if (!jsonMap.containsKey('references')) {
        print('\n=== 에러 ===');
        print('references 키가 존재하지 않습니다!');
        return null;
      }
      final references = jsonMap['references'] as Map<String, dynamic>;

      // 기존 references의 모든 내용을 copyList에 저장
      final copyList = Map<String, dynamic>.from(references);

      // copyList의 모든 오브젝트를 포함하는 바운딩 박스 계산
      double? minX;
      double? maxX;
      double? minY;
      double? maxY;

      copyList.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final x = (value['x'] as num?)?.toDouble() ?? 0;
          final y = (value['y'] as num?)?.toDouble() ?? 0;
          final width = (value['widgetWidth'] as num?)?.toDouble() ?? 0;
          final height = (value['widgetHeight'] as num?)?.toDouble() ?? 0;

          final leftEdge = x - (width / 2);
          final rightEdge = x + (width / 2);
          final topEdge = y - (height / 2);
          final bottomEdge = y + (height / 2);

          minX = minX == null ? leftEdge : (leftEdge < minX! ? leftEdge : minX);
          maxX =
              maxX == null ? rightEdge : (rightEdge > maxX! ? rightEdge : maxX);
          minY = minY == null ? topEdge : (topEdge < minY! ? topEdge : minY);
          maxY = maxY == null
              ? bottomEdge
              : (bottomEdge > maxY! ? bottomEdge : maxY);
        }
      });

      // 중점과 전체 크기 계산
      final centerX = ((minX ?? 0) + (maxX ?? 0)) / 2;
      final centerY = ((minY ?? 0) + (maxY ?? 0)) / 2;
      var width = (maxX ?? 0) - (minX ?? 0);
      var height = (maxY ?? 0) - (minY ?? 0);

      print('\n=== copyList 바운딩 박스 정보 ===');
      print('최소 X: $minX, 최대 X: $maxX');
      print('최소 Y: $minY, 최대 Y: $maxY');
      print('중점 (centerX, centerY): ($centerX, $centerY)');
      print('전체 Width: $width');
      print('전체 Height: $height');
      if (width < 100) width = 100;
      if (height < 100) height = 100;

      // copyList의 모든 좌표를 centerX, centerY 기준 상대 좌표로 변환
      copyList.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final x = (value['x'] as num?)?.toDouble() ?? 0;
          final y = (value['y'] as num?)?.toDouble() ?? 0;

          value['x'] = x - centerX;
          value['y'] = y - centerY;

          print('$key: 절대좌표 ($x, $y) -> 상대좌표 (${value['x']}, ${value['y']})');
        }
      });

      // 기존 references 내용을 모두 삭제
      references.clear();

      // 새로운 "A" 객체 생성 및 copyList를 meta에 저장
      references['A'] = {
        'x': centerX,
        'y': centerY,
        'rotation': 0,
        'scale': 1,
        'flipX': false,
        'flipY': false,
        'interaction': {
          'enableMove': true,
          'enableScale': true,
          'enableRotate': true,
          'enableSelection': true,
          'enableEdit': true,
        },
        'type': 'template',
        'exportConfigs': {
          'id': 'template-0',
          'width': width,
          'height': height,
          'meta': copyList,
        },
      };

      // historys의 layers를 {"id": "A"}로 교체
      if (jsonMap.containsKey('history') && jsonMap['history'] is List) {
        final historys = jsonMap['history'] as List;

        for (var history in historys) {
          if (history is Map<String, dynamic> &&
              history.containsKey('layers')) {
            history['layers'] = [
              {'id': 'A'}
            ];
          }
        }
      }

      return jsonMap;
    } catch (e) {
      print('=== JSON 수정 실패 ===');
      print('에러: $e');
      return null;
    }
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
          enableMinify: false,
        ),
      );

      print('history: ${await history.toJson()}');

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

  Future<void> _exportLayerState() async {
    try {
      final editor = editorKey.currentState;
      if (editor == null) return;

      final history = await editor.exportStateHistory(
        configs: const ExportEditorConfigs(
          historySpan: ExportHistorySpan.current,
          maxDecimalPlaces: 3,
          enableMinify: false,
        ),
      );

      final exportsDir = await _getLayerExportsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'layers_$timestamp.json';
      final filePath = '$exportsDir/$filename';

      await history.toFile(path: filePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('레이어보냄: $filename')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('레이어보내기 실패: $e')),
      );
    }
  }

  Future<void> _importLayerState() async {
    try {
      final exportsDir = await _getLayerExportsDirectory();
      final dir = Directory(exportsDir);
      final files = await dir
          .list()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장된 레이어 파일이 없습니다')),
        );
        return;
      }

      files.sort((a, b) => b.path.compareTo(a.path));

      if (!mounted) return;
      final selectedFile = await showDialog<String>(
        context: context,
        builder: (context) => _buildLayerExportListDialog(files),
      );

      if (selectedFile == null || !mounted) return;

      final file = File(selectedFile);
      final jsonString = await file.readAsString();
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      final history = ImportStateHistory.fromMap(
        jsonMap,
        configs: ImportEditorConfigs(
          recalculateSizeAndPosition: true,
          widgetLoader: widgetCustomLoader,
        ),
      );

      setState(() {
        _loadedHistory = history;
        _templateCreated = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      setState(() {
        _templateCreated = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('레이어 불러옴')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('레이어 불러오기 실패: $e')),
      );
    }
  }

  /// JSON 파일을 읽고 파싱하는 공통 함수
  Future<Map<String, dynamic>?> _readAndParseTemplateFile(
      String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      var jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      final modifiedJson = _modifyTemplateJson(jsonMap);
      if (modifiedJson == null) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('에러: references 키가 존재하지 않습니다'),
            duration: Duration(seconds: 2),
          ),
        );
        return null;
      }

      return modifiedJson;
    } catch (e) {
      print('템플릿 파일 파싱 실패: $e');
      return null;
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

      final jsonMap = await _readAndParseTemplateFile(selectedFile);
      if (jsonMap == null) return;

      final jsonDetail = const JsonEncoder.withIndent('  ').convert(jsonMap);
      final lines = jsonDetail.split('\n');
      for (final line in lines) {
        print(line);
      }

      final history = ImportStateHistory.fromMap(
        jsonMap,
        configs: ImportEditorConfigs(
          recalculateSizeAndPosition: true,
          widgetLoader: (
            String id, {
            Map<String, dynamic>? meta,
          }) {
            return widgetCustomLoader(id, meta: meta);
          },
        ),
      );

      setState(() {
        _loadedHistory = history;
        _templateCreated = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      setState(() {
        _templateCreated = true;
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

  Future<void> _loadTemplateFromFile(
    String filePath,
    void Function(WidgetLayer widget) setLayer,
  ) async {
    try {
      LoadingDialog.instance.show(
        context,
        configs: const ProImageEditorConfigs(),
        theme: Theme.of(context),
      );

      final jsonMap = await _readAndParseTemplateFile(filePath);
      if (jsonMap == null) {
        LoadingDialog.instance.hide();
        return;
      }

      final jsonDetail = const JsonEncoder.withIndent('  ').convert(jsonMap);
      final lines = jsonDetail.split('\n');
      for (final line in lines) {
        print(line);
      }

      final history = ImportStateHistory.fromMap(
        jsonMap,
        configs: ImportEditorConfigs(
          recalculateSizeAndPosition: true,
          widgetLoader: (
            String id, {
            Map<String, dynamic>? meta,
          }) {
            return widgetCustomLoader(id, meta: meta);
          },
        ),
      );

      LoadingDialog.instance.hide();

      setState(() {
        _loadedHistory = history;
        _templateCreated = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      setState(() {
        _templateCreated = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('템플릿 로드됨: ${filePath.split('/').last.split('\\').last}'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      LoadingDialog.instance.hide();
      print('템플릿 로드 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('템플릿 로드 실패: $e'),
          duration: const Duration(seconds: 2),
        ),
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

  Widget _buildLayerExportListDialog(List<FileSystemEntity> files) {
    return AlertDialog(
      title: const Text('레이어 파일 선택'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final filename = file.path.split('/').last.split('\\').last;
            final timestamp =
                filename.replaceAll('layers_', '').replaceAll('.json', '');

            return ListTile(
              leading: const Icon(Icons.upload_file),
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

  ReactiveWidget _buildSaveButton(Stream<void> rebuildStream) {
    return ReactiveWidget(
      stream: rebuildStream,
      builder: (_) {
        return Positioned(
          top: 60,
          left: 20,
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
          left: 20,
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

  ReactiveWidget _buildExportLayersButton(Stream<void> rebuildStream) {
    return ReactiveWidget(
      stream: rebuildStream,
      builder: (_) {
        return Positioned(
          top: 200,
          left: 20,
          child: FloatingActionButton(
            heroTag: 'export_layers_button',
            onPressed: _exportLayerState,
            backgroundColor: Colors.lightBlue,
            child: const Icon(
              Icons.send_to_mobile_outlined,
              color: Colors.white,
            ),
            tooltip: '레이어보내기',
          ),
        );
      },
    );
  }

  ReactiveWidget _buildImportLayersButton(Stream<void> rebuildStream) {
    return ReactiveWidget(
      stream: rebuildStream,
      builder: (_) {
        return Positioned(
          top: 270,
          left: 20,
          child: FloatingActionButton(
            heroTag: 'import_layers_button',
            onPressed: _importLayerState,
            backgroundColor: Colors.deepPurple,
            child: const Icon(
              Icons.upload_file,
              color: Colors.white,
            ),
            tooltip: '레이어 가져오기',
          ),
        );
      },
    );
  }

  void _addTextLayer(String text) {
    final editor = editorKey.currentState;
    if (editor == null) return;

    final layer = TextLayer(
      text: text,
      colorMode: LayerBackgroundMode.background,
      color: Colors.white,
      background: Colors.transparent,
      align: TextAlign.center,
    );

    editor.addLayer(layer);
  }

  ReactiveWidget _buildTemplateTextButtons(Stream<void> rebuildStream) {
    const presets = <({String label, String text})>[
      (label: '??Km', text: '??Km'),
      (label: 'HH:MM', text: 'HH:MM'),
      (label: 'M’SS”', text: 'M’SS”'),
    ];

    return ReactiveWidget(
      stream: rebuildStream,
      builder: (_) {
        return Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final preset in presets)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => _addTextLayer(preset.text),
                  child: Text(
                    preset.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTemplate(
    void Function(WidgetLayer widget) setLayer,
    ScrollController scrollController,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: FutureBuilder<List<FileSystemEntity>>(
        future: _loadTemplateFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '템플릿 로드 중 오류 발생: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final files = snapshot.data ?? [];

          if (files.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '저장된 템플릿이 없습니다.\n위의 저장 버튼을 눌러 템플릿을 만들어보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            controller: scrollController,
            itemCount: files.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final file = files[index];
              final filename = file.path.split('/').last.split('\\').last;
              final timestamp =
                  filename.replaceAll('template_', '').replaceAll('.json', '');

              return GestureDetector(
                onTap: () async {
                  await _loadTemplateFromFile(file.path, setLayer);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.black,
                            child: Center(
                              child: FutureBuilder<Widget?>(
                                future: _loadTemplatePreview(file.path),
                                builder: (context, previewSnapshot) {
                                  if (previewSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    );
                                  }

                                  if (previewSnapshot.hasError ||
                                      previewSnapshot.data == null) {
                                    return const Icon(
                                      Icons.layers,
                                      size: 40,
                                      color: Colors.white54,
                                    );
                                  }

                                  return FittedBox(
                                    fit: BoxFit.contain,
                                    child: previewSnapshot.data!,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(6),
                          color: Colors.white,
                          child: Text(
                            _formatTimestamp(timestamp),
                            style: const TextStyle(fontSize: 9),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<FileSystemEntity>> _loadTemplateFiles() async {
    try {
      final templatesDir = await _getTemplatesDirectory();
      final dir = Directory(templatesDir);

      if (!await dir.exists()) {
        return [];
      }

      final files = await dir
          .list()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      files.sort((a, b) => b.path.compareTo(a.path));

      return files;
    } catch (e) {
      print('템플릿 파일 로드 중 오류: $e');
      return [];
    }
  }

  Future<Widget?> _loadTemplatePreview(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      if (!jsonMap.containsKey('references')) {
        return null;
      }

      final references = jsonMap['references'] as Map<String, dynamic>;
      if (references.isEmpty) {
        return null;
      }

      final List<TextLayer> textLayers = [];

      double? minX;
      double? maxX;
      double? minY;
      double? maxY;

      references.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          try {
            final layer = Layer.fromMap(value, id: key);
            if (layer is TextLayer) {
              textLayers.add(layer);

              final x = layer.offset.dx;
              final y = layer.offset.dy;
              final width = layer.width ?? 0;
              final height = layer.height ?? 0;

              final leftEdge = x - (width / 2);
              final rightEdge = x + (width / 2);
              final topEdge = y - (height / 2);
              final bottomEdge = y + (height / 2);

              minX = minX == null
                  ? leftEdge
                  : (leftEdge < minX! ? leftEdge : minX);
              maxX = maxX == null
                  ? rightEdge
                  : (rightEdge > maxX! ? rightEdge : maxX);
              minY =
                  minY == null ? topEdge : (topEdge < minY! ? topEdge : minY);
              maxY = maxY == null
                  ? bottomEdge
                  : (bottomEdge > maxY! ? bottomEdge : maxY);
            }
          } catch (e) {
            print('레이어 파싱 오류: $e');
          }
        }
      });

      if (textLayers.isEmpty) {
        return null;
      }

      final totalWidth = (maxX ?? 0) - (minX ?? 0);
      final totalHeight = (maxY ?? 0) - (minY ?? 0);
      final centerX = ((minX ?? 0) + (maxX ?? 0)) / 2;
      final centerY = ((minY ?? 0) + (maxY ?? 0)) / 2;

      return SizedBox(
        width: totalWidth > 0 ? totalWidth : 100,
        height: totalHeight > 0 ? totalHeight : 100,
        child: Stack(
          children: [
            for (var textLayer in textLayers)
              Builder(
                builder: (context) {
                  final transformMatrix = calcTransformMatrix(textLayer);
                  return AlignPositioned(
                    dx: textLayer.offset.dx - centerX,
                    dy: textLayer.offset.dy - centerY,
                    child: Transform(
                      transform: transformMatrix,
                      alignment: Alignment.center,
                      child: _buildPreviewTextWidget(textLayer),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    } catch (e) {
      print('템플릿 미리보기 로드 실패: $e');
      return null;
    }
  }

  Widget _buildPreviewTextWidget(TextLayer layer) {
    final fontSize = textEditorConfigs.initFontSize * layer.scale;
    final style = TextStyle(
      fontSize: fontSize * layer.fontScale,
      color: layer.color,
      overflow: TextOverflow.ellipsis,
    );

    final maxTextWidth = layer.maxTextWidth;

    return RoundedBackgroundText(
      enableHitBoxCorrection: true,
      maxTextWidth:
          maxTextWidth == null ? double.infinity : maxTextWidth * layer.scale,
      layer.text.toString(),
      backgroundColor: layer.background,
      textAlign: layer.align,
      style: layer.textStyle?.copyWith(
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            color: style.color,
            fontFamily: style.fontFamily,
          ) ??
          style,
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
                  exportConfigs: WidgetLayerExportConfigs(
                    id: 'sticker-$index',
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
          tools: [
            SubEditorMode.text,
            SubEditorMode.template,
          ],
          enableCloseButton: !isDesktopMode(context),
          widgets: MainEditorWidgets(
            bodyItems: (editor, rebuildStream) {
              return [
                _buildSaveButton(rebuildStream),
                _buildLoadButton(rebuildStream),
                _buildExportLayersButton(rebuildStream),
                _buildImportLayersButton(rebuildStream),
                _buildTemplateTextButtons(rebuildStream),
              ];
            },
          ),
        ),
        stateHistory: StateHistoryConfigs(
          initStateHistory: _loadedHistory,
        ),
        textEditor: textEditorConfigs,
        templateEditor: TemplateEditorConfigs(
          enabled: true,
          builder: (setLayer, scrollController) {
            return buildTemplate(setLayer, scrollController);
          },
        ),
        stickerEditor: StickerEditorConfigs(
          builder: (setLayer, scrollController) {
            return buildStickers(setLayer, scrollController);
          },
        ),
      ),
    );
  }

  Widget widgetCustomLoader(String id, {Map<String, dynamic>? meta}) {
    print('\n=== widgetCustomLoader 호출 ===');
    print('id: $id');

    List<TextLayer> textLayers = [];

    if (meta != null && meta.isNotEmpty) {
      meta.forEach((key, value) {
        textLayers.add(
            Layer.fromMap(value as Map<String, dynamic>, id: key) as TextLayer);
        print('키: $key');
        print('값: $value');
      });
    } else {
      print('meta가 null이거나 비어있습니다');
    }

    return Stack(
      key: GlobalKey(),
      children: [
        for (var textLayer in textLayers)
          Builder(
            builder: (context) {
              Matrix4 transformMatrix = calcTransformMatrix(textLayer);
              return AlignPositioned(
                dx: textLayer.offset.dx,
                dy: textLayer.offset.dy,
                child: Transform(
                  transform: transformMatrix,
                  alignment: Alignment.center,
                  child: buildTextWidget(textLayer),
                ),
              );
            },
          ),
      ],
    );
  }

  Matrix4 calcTransformMatrix(Layer layer) {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(layer.flipY ? pi : 0)
      ..rotateY(layer.flipX ? pi : 0)
      ..rotateZ(layer.rotation);
  }

  Widget buildTextWidget(TextLayer layer) {
    var fontSize = textEditorConfigs.initFontSize * layer.scale;
    var style = TextStyle(
      fontSize: fontSize * layer.fontScale,
      color: layer.color,
      overflow: TextOverflow.ellipsis,
    );

    final maxTextWidth = layer.maxTextWidth;

    return RoundedBackgroundText(
      enableHitBoxCorrection: true,
      maxTextWidth:
          maxTextWidth == null ? double.infinity : maxTextWidth * layer.scale,
      layer.text.toString(),
      backgroundColor: layer.background,
      textAlign: layer.align,
      style: layer.textStyle?.copyWith(
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            color: style.color,
            fontFamily: style.fontFamily,
          ) ??
          style,
    );
  }
}
