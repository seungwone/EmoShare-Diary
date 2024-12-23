import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emoshare_diary/common/const/colors.dart';
import 'package:emoshare_diary/common/const/data.dart';
import 'package:emoshare_diary/common/database/drift_database.dart';
import 'package:emoshare_diary/common/layout/default_layout.dart';
import 'package:emoshare_diary/diary/component/custom_text_form_field.dart';
import 'package:emoshare_diary/diary/component/emotion_alert_dialog.dart';
import 'package:emoshare_diary/diary/component/loading_alert_dialog.dart';
import 'package:emoshare_diary/diary/component/recording_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class DiaryEditScreen extends ConsumerStatefulWidget {
  static String get routeName => 'diaryedit';

  final DateTime date;

  DiaryEditScreen({
    super.key,
    required String date,
  }) : date = DateTime.parse(date);

  @override
  ConsumerState<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends ConsumerState<DiaryEditScreen> {
  final formKey = GlobalKey<FormState>();
  final _topFocus = FocusNode();
  final _diaryFocus = FocusNode();
  final _summaryFocus = FocusNode();
  bool isLoading = true;
  bool isCreated = false;
  bool isInitState = true;
  final TextEditingController _mainTextEditingController =
      TextEditingController(text: '');
  String summary = '';
  DiaryInfo? diaryInfo;
  bool autofocus = true;
  final TextEditingController _summaryTextEditingController =
      TextEditingController(text: '');
  MemoryImage? diaryImageProvider;

  KeyboardActionsConfig _buildKeyboardActionsConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: PRIMARY_COLOR,
      actions: [
        _buildKeyboardActionsItem(_diaryFocus),
        _buildKeyboardActionsItem(_summaryFocus),
      ],
    );
  }

  KeyboardActionsItem _buildKeyboardActionsItem(FocusNode focusNode) {
    return KeyboardActionsItem(
      focusNode: focusNode,
      displayArrows: false,
      displayActionBar: false,
      footerBuilder: (_) => PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Row(
          children: [
            const Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: SizedBox(),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          _diaryFocus.unfocus();
                          final String? text = await showModalBottomSheet(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16.0),
                                topRight: Radius.circular(16.0),
                              ),
                            ),
                            isDismissible: false,
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.3,
                              minHeight:
                                  MediaQuery.of(context).size.height * 0.3,
                              maxWidth: double.infinity,
                              minWidth: double.infinity,
                            ),
                            enableDrag: false,
                            context: context,
                            builder: (context) {
                              return const RecordingBox();
                            },
                          );

                          if (text != null) {
                            formKey.currentState!.save();
                            if (focusNode == _diaryFocus) {
                              if (_mainTextEditingController.text.isNotEmpty) {
                                _mainTextEditingController.text += ' ';
                              }
                              _mainTextEditingController.text += text;
                            } else if (focusNode == _summaryFocus) {
                              if (summary != '') {
                                summary += ' ';
                              }
                              summary += text;
                            }
                            setState(() {});
                          }
                        },
                        icon: const Icon(
                          Icons.mic,
                          color: PRIMARY_COLOR,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    focusNode.unfocus();
                  },
                  child: const Text(
                    '완료',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    ref.read(localDatabaseProvider).watchDiaryInfos(widget.date).first.then(
      (value) {
        setState(() {
          diaryInfo = value;
          isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localDatabase = ref.watch(localDatabaseProvider);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (diaryInfo != null && isInitState) {
      isCreated = true;
      autofocus = false;
      _mainTextEditingController.text = diaryInfo!.content;
      _summaryTextEditingController.text = diaryInfo!.summary;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 이미지 로드
        if (diaryInfo!.image != null) {
          setState(() {
            diaryImageProvider = MemoryImage(diaryInfo!.image!);
          });
        }
      });

      isInitState = false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        autofocus = false;
        final resp = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            surfaceTintColor: BACKGROUND_COLOR,
            backgroundColor: BACKGROUND_COLOR,
            content: const Text(
              '저장하지 않고 종료하시겠습니까?',
              style: TextStyle(fontSize: 16.0),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  context.pop(true);
                },
                child: const Text('예'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  context.pop();
                },
                child: const Text('아니오'),
              ),
            ],
          ),
        );

        if (resp != true) {
          return;
        }

        if (context.mounted) {
          context.pop();
        }
      },
      child: DefaultLayout(
        title: '${widget.date.year}년 ${widget.date.month}월 ${widget.date.day}일',
        actions: [
          TextButton(
            onPressed: () async {
              if (!isLoading) {
                formKey.currentState!.save();

                showDialog(
                  context: context,
                  builder: (context) => EmotionAlertDialog(
                    isCreated: isCreated,
                    localDatabase: localDatabase,
                    date: widget.date,
                    content: _mainTextEditingController.text,
                    summary: summary,
                    emotion: diaryInfo?.emotion ?? 2,
                    image: diaryImageProvider?.bytes,
                  ),
                );
              }
            },
            child: const Text(
              '저장',
              style: TextStyle(
                color: Colors.blue,
              ),
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: KeyboardActions(
              config: _buildKeyboardActionsConfig(context),
              child: Column(
                children: [
                  Focus(
                    focusNode: _topFocus,
                    child: const SizedBox(),
                  ),
                  CustomTextFormField(
                    valueKey: const ValueKey(2),
                    onSaved: (value) {
                      if (value != null) {
                        summary = value;
                      } else {
                        summary = '';
                      }
                    },
                    hintText: '오늘의 일기를 간단하게 요약해주세요.\n자동요약 기능을 사용해보세요.',
                    textEditingController: _summaryTextEditingController,
                    minLines: 3,
                    maxLines: null,
                    inputBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    focusNode: _summaryFocus,
                  ),
                  const SizedBox(height: 16.0),
                  Container(
                    height: 2.0,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(
                        Radius.circular(16.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  GestureDetector(
                    onTap: () async {
                      // 이미지 선택
                      final image = await ImagePicker()
                          .pickImage(source: ImageSource.gallery);

                      if (image == null) return;

                      final file = File(image.path);

                      setState(() {
                        diaryImageProvider =
                            MemoryImage(file.readAsBytesSync());
                      });
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width / 2,
                      height: MediaQuery.sizeOf(context).width / 2,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: PRIMARY_COLOR,
                          width: 2.0,
                        ),
                      ),
                      child: diaryImageProvider != null
                          ? Image(
                              image: diaryImageProvider!,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Icon(
                                Icons.camera_alt,
                                color: PRIMARY_COLOR,
                                size: 48.0,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        diaryImageProvider = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PRIMARY_COLOR,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('이미지 삭제'),
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextFormField(
                    valueKey: const ValueKey(1),
                    textEditingController: _mainTextEditingController,
                    hintText: '일기를 작성해주세요.',
                    minLines: 5,
                    maxLines: null,
                    autofocus: autofocus,
                    focusNode: _diaryFocus,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      formKey.currentState!.save();

                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) => const LoadingAlertDialog(),
                      );

                      final response = await Dio().post(
                        '$baseUrl/summarize',
                        data: {
                          'content': _mainTextEditingController.text,
                        },
                      );

                      autofocus = false;

                      _summaryTextEditingController.text = response.data;

                      Scrollable.ensureVisible(
                        _topFocus.context!,
                        duration: const Duration(milliseconds: 300),
                      );

                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PRIMARY_COLOR,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('일기 자동요약'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
