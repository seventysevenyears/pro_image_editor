import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:example/features/stickers_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_background_remover/image_background_remover.dart';
import 'package:pro_image_editor/core/models/layers/layer_interaction.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '/core/mixin/example_helper.dart';

/// A simple file editor widget that opens the ProImageEditor with a file
class SimpleFileEditor extends StatefulWidget {
  /// The image file to edit
  final File file;

  /// Creates a new [SimpleFileEditor] widget.
  const SimpleFileEditor({
    super.key,
    required this.file,
  });

  @override
  State<SimpleFileEditor> createState() => _SimpleFileEditorState();
}

class _SimpleFileEditorState extends State<SimpleFileEditor>
    with ExampleHelperState<SimpleFileEditor> {
  final GlobalKey<ProImageEditorState> _key = GlobalKey<ProImageEditorState>();
  late final ProImageEditorConfigs _configs = ProImageEditorConfigs(
    designMode: platformDesignMode,
    cropRotateEditor: const CropRotateEditorConfigs(
      enabled: false,
    ),
    tuneEditor: const TuneEditorConfigs(
      enabled: false,
    ),
    blurEditor: const BlurEditorConfigs(
      enabled: false,
    ),
    emojiEditor: const EmojiEditorConfigs(
      enabled: false,
    ),
    stickerEditor: StickerEditorConfigs(
      // builder: (setLayer, scrollController) {
      //   // Optionally your code to pick layers
      //   return const SizedBox();
      // },
      enabled: false,
    ),
    textEditor: const TextEditorConfigs(
      enabled: true,
    ),
    filterEditor: const FilterEditorConfigs(
      enabled: false,
    ),
    mainEditor: const MainEditorConfigs(
      enableCloseButton: false,
    ),
    paintEditor: const PaintEditorConfigs(
      enabled: false,
    ),
  );

  late final ProImageEditorCallbacks _callbacks = ProImageEditorCallbacks(
    onImageEditingStarted: onImageEditingStarted,
    onImageEditingComplete: onImageEditingComplete,
    onCloseEditor: (editorMode) => onCloseEditor(editorMode: editorMode),
    mainEditorCallbacks: MainEditorCallbacks(
      onAfterViewInit: _onStartEditor,
      helperLines: HelperLinesCallbacks(onLineHit: vibrateLineHit),
    ),
  );

  void _onStartEditor() async {
    // 에디터가 완전히 로드된 후 실행할 초기화 작업
    print('에디터가 로드되었습니다. 버튼을 눌러 배경 제거를 시도해보세요.');

    // 원하는 함수의 주석을 해제하세요:
    // await _extractPersonAndAddImage(); // Google ML Kit 방식
    //await _removeBackgroundAndAddImage(); // Background Remover 방식
  }

  /// Image Background Remover를 사용하여 배경을 제거하고 사람 부분만 추출
  Future<void> _removeBackgroundAndAddImage() async {
    try {
      // Background Remover 초기화
      BackgroundRemover.instance.initializeOrt();

      // 로딩 다이얼로그 표시
      LoadingDialog dialog = LoadingDialog.instance
        ..show(
          context,
          configs: const ProImageEditorConfigs(),
        );

      // 파일을 바이트로 읽기
      final imageBytes = await widget.file.readAsBytes();

      // Background Remover를 사용하여 배경 제거
      final resultImage = await BackgroundRemover.instance.removeBg(
        imageBytes,
        threshold: 0.5, // 임계값 (0.0~1.0)
        enhanceEdges: true, // 가장자리 향상
        smoothMask: true, // 마스크 스무딩
      );

      if (!mounted) return;

      // 알파값 이진화
      final binarizedImage = await _binarizeAlpha(resultImage);
      //_addTestText();
      _addTestWidget();
      //_addImageWidget(binarizedImage);

      // UI Image를 바이트로 변환
      // var resultBytes = await ImageConverter.instance.uiImageToImageBytes(
      //   resultImage,
      //   context: context,
      // );

      // 로딩 다이얼로그 숨기기
      dialog.hide();

      // 결과 이미지를 _addImage 함수에 전달
      // if (resultBytes != null) {
      //   _addImage(resultBytes);
      // }

      // Background Remover 리소스 정리
      BackgroundRemover.instance.dispose();
    } catch (e) {
      print('배경 제거 중 오류 발생: $e');
    }
  }

  /// ui.Image의 알파값을 0 또는 255로 이진화
  Future<ui.Image> _binarizeAlpha(ui.Image image, {int threshold = 254}) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to get image ByteData");

    final rgbaBytes = byteData.buffer.asUint8List();
    final outBytes = Uint8List(rgbaBytes.length);

    for (int i = 0; i < rgbaBytes.length; i += 4) {
      if (rgbaBytes[i + 3] != 255) {
        outBytes[i] = 0; // R
        outBytes[i + 1] = 0; // G
        outBytes[i + 2] = 0; // B
        outBytes[i + 3] = 0;
      } else {
        outBytes[i] = rgbaBytes[i]; // R
        outBytes[i + 1] = rgbaBytes[i + 1]; // G
        outBytes[i + 2] = rgbaBytes[i + 2]; // B
        outBytes[i + 3] = 255;
      }

      // 알파값이 threshold(기본 254) 이상이면 255, 아니면 0
      // outBytes[i + 3] = rgbaBytes[i + 3] >= threshold ? 255 : 0;
      //outBytes[i + 3] = 0;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      outBytes,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) => completer.complete(img),
    );

    return completer.future;
  }

  void _addImageWidget(ui.Image image) async {
    if (!mounted) return;

    _key.currentState!.addLayer(
      autoCorrectZoomScale: false,
      autoCorrectZoomOffset: false,
      blockSelectLayer: true,
      blockCaptureScreenshot: true,
      WidgetLayer(
        interaction: LayerInteraction(
          enableSelection: false,
          enableScale: false,
          enableEdit: false,
          enableRotate: false,
          enableMove: false,
        ),
        offset: Offset.zero,
        width: _key.currentState!.sizesManager.bodySize.width,
        scale: 1,
        widget: RawImage(
          image: image,
        ),
      ),
    );
    setState(() {});
  }

  void _addTestWidget() {
    final editor = _key.currentState;
    if (editor != null) {
      editor.addLayer(
        WidgetLayer(
          widget: Text('Test'),
        ),
      );
    }
  }

  void _addTestText() {
    final editor = _key.currentState;
    if (editor != null) {
      // 큰 숫자 "1.14" 레이어
      final largeNumberLayer = TextLayer(
        text: '1.14',
        colorMode: LayerBackgroundMode.onlyColor,
        color: Colors.white,
        align: TextAlign.center,
        fontScale: 20.0,
        offset: const Offset(0.5, 0.35), // 중앙 상단
      );

      // 시간 "1:23:52" 레이어
      final timeLayer = TextLayer(
        text: '1:23:52',
        colorMode: LayerBackgroundMode.onlyColor,
        color: Colors.white,
        align: TextAlign.left,
        fontScale: 5.0,
        offset: const Offset(0.15, 0.75), // 하단 왼쪽
      );

      // 해시태그 "#러닝" 레이어
      final hashtagLayer = TextLayer(
        text: '#러닝',
        colorMode: LayerBackgroundMode.onlyColor,
        color: Colors.white,
        align: TextAlign.center,
        fontScale: 5.0,
        offset: const Offset(0.5, 0.75), // 하단 중앙
      );

      // 속도 "73:34/KM" 레이어
      final speedLayer = TextLayer(
        text: '73:34/KM',
        colorMode: LayerBackgroundMode.onlyColor,
        color: Colors.white,
        align: TextAlign.right,
        fontScale: 5.0,
        offset: const Offset(0.85, 0.75), // 하단 오른쪽
      );

      // 에디터에 텍스트 레이어들 추가
      editor.addLayer(largeNumberLayer);
      editor.addLayer(timeLayer);
      editor.addLayer(hashtagLayer);
      editor.addLayer(speedLayer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ProImageEditor
          ProImageEditor.file(
            widget.file,
            key: _key,
            callbacks: _callbacks,
            configs: _configs,
          ),
          // 버튼 오버레이들
          Positioned(
            top: 50,
            right: 20,
            child: SafeArea(
              child: Column(
                children: [
                  // Background Remover 방식 버튼
                  FloatingActionButton(
                    heroTag: 'bg_remover_button',
                    onPressed: () async {
                      await _removeBackgroundAndAddImage();
                    },
                    backgroundColor: Colors.green,
                    child: const Icon(
                      Icons.content_cut,
                      color: Colors.white,
                    ),
                    tooltip: 'Background Remover로 배경 제거',
                  ),
                  const SizedBox(height: 10),
                  // 텍스트 추가 버튼
                  FloatingActionButton(
                    heroTag: 'add_text_button',
                    onPressed: _addTestText,
                    backgroundColor: Colors.orange,
                    child: const Icon(
                      Icons.text_fields,
                      color: Colors.white,
                    ),
                    tooltip: '테스트 텍스트 추가',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
