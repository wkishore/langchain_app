//import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_app/config/config.dart';
import 'package:langchain_app/services/langchain/langchain_services_implementation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
//import 'package:langchain_core/document_loaders.dart';
import 'package:langchain_community/langchain_community.dart';
part 'index_notifier.g.dart';


enum IndexState{
  initial,
  loading,
  loaded,
  error,
}

@riverpod
class IndexNotifier extends _$IndexNotifier{
  @override
  IndexState build()=> IndexState.initial;

  void createAndUploadPineConeIndex() async{
    const vectorDimension = 768;
    state = IndexState.loading;
    try{
      await ref.read(langchainServiceProvider).createPineConeIndex(ServiceConfig.indexName, vectorDimension);
      final docs = await fetchDocuments(); 
      await ref.read(langchainServiceProvider).updatePineConeIndex(ServiceConfig.indexName, docs);
      //print('pinecone index updated');
      state = IndexState.loaded;
    }catch(e){
      state = IndexState.error;
    }
  }

  Future<List<Document>> fetchDocuments() async{
    try{
      final textFilePathfromPdf = await convertPdfToText();
      final loader = TextLoader(textFilePathfromPdf);
      final documents = await loader.load();
      return documents;
    }catch(e){
      throw Exception('error loading text file');
    }
  }

  Future<String> convertPdfToText() async{
    try {
      //
      final pdfDoc = await rootBundle.load('assets/pdf/sample.pdf');
      final document = PdfDocument(inputBytes: pdfDoc.buffer.asUint8List());
      String text = PdfTextExtractor(document).extractText();
      final localPath = await _localPath;
      File file = File('$localPath/output.txt');
      final res = await file.writeAsString(text);

      document.dispose();
      return res.path;
    } catch (e) {
      throw Exception('error getting file from pdf');
    }
  }

  Future<String> get _localPath async{
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}