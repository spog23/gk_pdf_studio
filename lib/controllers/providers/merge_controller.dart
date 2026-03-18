import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pdf_source_document.dart';
import '../../services/pdf_service.dart';

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final mergeControllerProvider =
    NotifierProvider<MergeController, MergeState>(MergeController.new);

class MergeState {
  const MergeState({
    this.isLoading = false,
    this.outputFile,
    this.errorMessage,
  });

  final bool isLoading;
  final File? outputFile;
  final String? errorMessage;

  MergeState copyWith({
    bool? isLoading,
    File? outputFile,
    String? errorMessage,
    bool clearOutputFile = false,
    bool clearErrorMessage = false,
  }) {
    return MergeState(
      isLoading: isLoading ?? this.isLoading,
      outputFile: clearOutputFile ? null : outputFile ?? this.outputFile,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class MergeController extends Notifier<MergeState> {
  @override
  MergeState build() {
    return const MergeState();
  }

  Future<File> mergeFiles(
    List<PdfSourceDocument> documents,
    String outputPath,
  ) async {
    final pdfService = ref.read(pdfServiceProvider);

    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
    );

    try {
      final outputFile = await pdfService.mergePdfFiles(
        documents,
        outputPath,
      );

      state = state.copyWith(
        isLoading: false,
        outputFile: outputFile,
        clearErrorMessage: true,
      );

      return outputFile;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        clearOutputFile: true,
      );
      rethrow;
    }
  }
}
