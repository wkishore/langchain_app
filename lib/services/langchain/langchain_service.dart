import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:langchain/langchain.dart';

abstract class ILangchainService{
  Future<void> createPineConeIndex(String indexName, int vectorDimension);
  Future<void> updatePineConeIndex(String indexName, List<Document> docs);
  Future<String> queryPineConeVectorStore(String indexName, String query);
  Future<String> onImageClick(BuildContext context, CameraDescription firstCamera,ImageLabeler imageLabeler);
}