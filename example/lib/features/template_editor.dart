// Dart imports:
import 'dart:io';
import 'dart:convert';
import 'dart:math';

// Flutter imports:
import 'package:align_positioned/align_positioned.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_image_editor/features/text_editor/widgets/rounded_background_text/rounded_background_text.dart';
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
  final GlobalKey<ProImageEditorState> _key = GlobalKey<ProImageEditorState>();
  bool _ignorePlatformIssue = false;
  bool _templateCreated = false;
  TextEditorConfigs textEditorConfigs = TextEditorConfigs();

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
    textEditorConfigs = TextEditorConfigs(
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
    );
  }

  Future<String> _getTemplatesDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final templatesDir = Directory('${directory.path}/templates');
    if (!await templatesDir.exists()) {
      await templatesDir.create(recursive: true);
    }
    return templatesDir.path;
  }

  /// JSON 템플릿을 수정하는 함수
  /// references의 모든 내용을 새로운 "A" 위젯의 meta에 복사
  Map<String, dynamic>? _modifyTemplateJson(Map<String, dynamic> jsonMap) {
    try {
      // references 키 확인
      if (!jsonMap.containsKey('references')) {
        print('\n=== 에러 ===');
        print('references 키가 존재하지 않습니다!');

        final jsonDetail = const JsonEncoder.withIndent('  ').convert(jsonMap);
        final lines = jsonDetail.split('\n');
        for (final line in lines) {
          print(line);
        }
        return null;
      }
      final references = jsonMap['references'] as Map<String, dynamic>;

      // 기존 references의 모든 내용을 copyList에 저장
      final copyList = Map<String, dynamic>.from(references);

      // copyList의 모든 x, y 값에서 절대값 기준 최대값 찾기
      double maxAbsX = 0;
      double maxAbsY = 0;

      copyList.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final x = (value['x'] as num?)?.toDouble() ?? 0;
          final y = (value['y'] as num?)?.toDouble() ?? 0;

          final absX = x.abs();
          final absY = y.abs();

          if (absX > maxAbsX) maxAbsX = absX;
          if (absY > maxAbsY) maxAbsY = absY;
        }
      });

      print('\n=== copyList 절대값 최대 좌표 ===');
      print('최대 절대값 X: $maxAbsX');
      print('최대 절대값 Y: $maxAbsY');
      var width = maxAbsX * 2;
      var height = maxAbsY * 2;
      if (width < 100) width = 100;
      if (height < 100) height = 100;
      // 기존 references 내용을 모두 삭제
      references.clear();

      // 새로운 "A" 객체 생성 및 copyList를 meta에 저장
      references['A'] = {
        'x': 0,
        'y': 0,
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
          'meta': copyList, // 원본 references를 copyList로 저장
        },
      };

      // historys의 layers를 {"id": "A"}로 교체
      if (jsonMap.containsKey('history') && jsonMap['history'] is List) {
        final historys = jsonMap['history'] as List;

        for (var history in historys) {
          if (history is Map<String, dynamic> &&
              history.containsKey('layers')) {
            // layers를 {"id": "A"}로 교체
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
      var jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      // JSON 수정 적용
      final modifiedJson = _modifyTemplateJson(jsonMap);
      if (modifiedJson == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('에러: references 키가 존재하지 않습니다'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      jsonMap = modifiedJson;

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

            // switch (id) {
            //   case 'my-special-container':
            //     return Container(
            //       width: 100,
            //       height: 100,
            //       color: Colors.amber,
            //     );

            //   /// ... other widgets
            // }
            // throw ArgumentError(
            //   'No widget found for the given id: $id',
            // );
          },
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

      // Read and modify JSON file
      final file = File(selectedFile);
      final jsonString = await file.readAsString();
      var jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      print('=== 원본 템플릿 파일 ===');
      print('파일 경로: $selectedFile');
      print('파일명: ${selectedFile.split('/').last.split('\\').last}');

      // JSON 수정 적용
      final modifiedJson = _modifyTemplateJson(jsonMap);
      if (modifiedJson == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('에러: references 키가 존재하지 않습니다'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      jsonMap = modifiedJson;

      print('\n=== 수정된 JSON 내용 ===');
      final jsonDetail = const JsonEncoder.withIndent('  ').convert(jsonMap);
      final lines = jsonDetail.split('\n');
      for (final line in lines) {
        print(line);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '템플릿 변환 완료: ${selectedFile.split('/').last.split('\\').last}'),
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
        textEditor: textEditorConfigs,
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

  Widget widgetCustomLoader(String id, {Map<String, dynamic>? meta}) {
    print('\n=== widgetCustomLoader 호출 ===');
    print('id: $id');

    List<TextLayer> textLayers = [];

    // 바운딩 박스 관련 변수 미리 선언
    double minX = 0;
    double maxX = 0;
    double minY = 0;
    double maxY = 0;
    double totalWidth = 0;
    double totalHeight = 0;
    double centerX = 0;
    double centerY = 0;

    if (meta != null && meta.isNotEmpty) {
      // print('\n=== meta 값들 ===');
      meta.forEach((key, value) {
        textLayers.add(
            Layer.fromMap(value as Map<String, dynamic>, id: key) as TextLayer);
        print('키: $key');
        print('값: $value');
        // print('타입: ${value.runtimeType}');

        // // Map 타입인 경우 내부 내용도 출력
        // if (value is Map<String, dynamic>) {
        //   print('  상세 내용:');
        //   value.forEach((subKey, subValue) {
        //     print('    $subKey: $subValue');
        //   });
        // }
        // print('---');
      });

      // 모든 레이어를 포함하는 바운딩 박스 계산
      if (textLayers.isNotEmpty) {
        double maxAbsX = 0;
        double maxAbsY = 0;

        for (var layer in textLayers) {
          // 각 레이어의 위치 (x, y)
          final x = layer.offset.dx;
          final y = layer.offset.dy;

          // 절대값으로 가장 큰 값 찾기
          final absX = x.abs();
          final absY = y.abs();

          if (absX > maxAbsX) maxAbsX = absX;
          if (absY > maxAbsY) maxAbsY = absY;
        }

        totalWidth = maxAbsX * 2;
        totalHeight = maxAbsY * 2;
        centerX = 0;
        centerY = 0;
        if (totalWidth < 100) totalWidth = 100;
        if (totalHeight < 100) totalHeight = 100;

        print('\n=== 바운딩 박스 정보 ===');
        print('중간점 (centerX, centerY): ($centerX, $centerY)');
        print('전체 가로 길이: $totalWidth');
        print('전체 세로 길이: $totalHeight');
        print('최소 X: $minX, 최대 X: $maxX');
        print('최소 Y: $minY, 최대 Y: $maxY');
      }
    } else {
      print('meta가 null이거나 비어있습니다');
    }

    // TextLayer layer = Layer.fromMap(meta ?? {}) as TextLayer;

    // editorKey.currentState?.addLayer(
    //   WidgetLayer(
    //     widget: Container(
    //       width: 384,
    //       height: 384,
    //       color: Colors.amber,
    //     ),
    //   ),
    // );
    //return Container();
    // return Row(
    //   children: [
    //     buildTextWidget(textLayers[0]),
    //     buildTextWidget(textLayers[1]),
    //   ],
    // );

    return Stack(
      key: GlobalKey(),
      children: [
        for (var textLayer in textLayers)
          Builder(builder: (context) {
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
          }),
        //buildTextWidget(textLayers[1]),
        //for (var textLayer in textLayers) buildTextWidget(textLayer),
        // Positioned(
        //   top: 34,
        //   left: 54,
        //   child: Text('Hello2'),
        // ),
        // Positioned(
        //   top: 68,
        //   left: 108,
        //   child: Text('Hello3'),
        // ),
      ],
    );
  }

  Matrix4 calcTransformMatrix(Layer layer) {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Add a small z-offset to avoid rendering issues
      ..rotateX(layer.flipY ? pi : 0)
      ..rotateY(layer.flipX ? pi : 0)
      ..rotateZ(layer.rotation);
  }

  Widget buildTextWidget(TextLayer layer) {
    // return Container(
    //   alignment: Alignment.center,
    //   color: Colors.red,
    //   width: 10,
    //   height: 10,
    // );
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
