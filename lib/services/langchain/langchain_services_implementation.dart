import 'dart:convert';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:langchain_app/views/camera_controller.dart';
import 'package:langchain_app/config/config.dart';
import 'package:langchain_app/services/langchain/langchain_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_pinecone/langchain_pinecone.dart';
import 'package:pinecone/pinecone.dart';
import 'package:langchain_google/langchain_google.dart';

final langchainServiceProvider = Provider<ILangchainService>((ref) {
  final pineConeApiKey = dotenv.env['PINECONE_API_KEY']!;
  final environment = dotenv.env['PINECONE_ENVIRONMENT']!;
  final googleApiKey = dotenv.env['GEMINI_API_KEY'];
  final pineconeClient = PineconeClient(
    apiKey: pineConeApiKey,
    baseUrl: 'https://controller.$environment.pinecone.io',
  );

  final embeddings = GoogleGenerativeAIEmbeddings(apiKey: googleApiKey, model: 'text-embedding-004');

  final langchainPinecone = Pinecone(
    apiKey: pineConeApiKey,
    indexName: ServiceConfig.indexName,
    embeddings: embeddings,
    environment: environment,
  );

  final gemini = ChatGoogleGenerativeAI(apiKey: googleApiKey, defaultOptions: const ChatGoogleGenerativeAIOptions(model: 'gemini-1.5-pro-latest'));
  return LangchainServiceImpl(
    client: pineconeClient,
    langchainPinecone: langchainPinecone,
    embeddings: embeddings,
    openAI: gemini,
  );
});

class LangchainServiceImpl implements ILangchainService {
  final PineconeClient client;
  final Pinecone langchainPinecone;
  final GoogleGenerativeAIEmbeddings embeddings;
  final ChatGoogleGenerativeAI openAI;

  LangchainServiceImpl({
    required this.client,
    required this.langchainPinecone,
    required this.embeddings,
    required this.openAI,
  });
  @override
  Future<void> createPineConeIndex(
      String indexName, int vectorDimension) async {
    final indexes = await client.listIndexes();
    try {
      if (!indexes.contains(indexName)) {
        await client.createIndex(
          environment: dotenv.env['PINECONE_ENVIRONMENT']!,
          request: CreateIndexRequest(
            name: indexName,
            dimension: vectorDimension,
            metric: SearchMetric.cosine,
          ),
        );
        // await Future.delayed(const Duration(seconds: 5));
      } else {
      }
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Future<String> queryPineConeVectorStore(
      String indexName, String query) async {
    try {
      final index = await client.describeIndex(
          indexName: indexName,
          environment: dotenv.env['PINECONE_ENVIRONMENT']!);
      final queryEmbedding = await embeddings.embedQuery(query);
      final result = await PineconeClient(
              apiKey: dotenv.env['PINECONE_API_KEY']!,
              baseUrl:
                  'https://${index.name}-${index.projectId}.svc.${index.environment}.pinecone.io')
          .queryVectors(
        indexName: index.name,
        projectId: index.projectId,
        environment: index.environment,
        request: QueryRequest(
          topK: 10,
          vector: queryEmbedding,
          includeMetadata: true,
          includeValues: true,
        ),
      );
      if (result.matches.isNotEmpty) {
        final concatPageContent = result.matches.map((e) {
          if (e.metadata == null) return '';
          // check if the metadata has a 'pageContent' key
          if (e.metadata!.containsKey('pageContent')) {
            return e.metadata!['pageContent'];
          } else {
            return '';
          }
        }).join(' ');

        final docChain = StuffDocumentsQAChain(llm: openAI);
        final response = await docChain.call({
          'input_documents': [Document(pageContent: concatPageContent)],
          'question': query,
        });


        return response['output'];
      } else {
        return 'No results found';
      }
    } catch (e) {
      throw Exception('Error querying pinecone index');
    }
  }

  @override
  Future<void> updatePineConeIndex(
      String indexname, List<Document> docs) async {
    try {
      final index = await client.describeIndex(
          indexName: indexname,
          environment: dotenv.env['PINECONE_ENVIRONMENT']!);

      for (final doc in docs) {
        final txtPath = doc.metadata['source'] as String;
        final text = doc.pageContent;

        const textSplitter = RecursiveCharacterTextSplitter(chunkSize: 1000);

        final chunks = textSplitter.createDocuments([text]);



        final chunksMap = chunks
            .map(
              (e) => Document(
                id: e.id,
                pageContent: e.pageContent.replaceAll(RegExp('/\n/g'), "  "),
                metadata: doc.metadata,
              ),
            )
            .toList();

        final embeddingArrays = await embeddings.embedDocuments(chunksMap);

        const batchSize = 100;
        for (int i = 0; i < chunks.length; i++) {
          final chunk = chunks[i];
          final embeddingArray = embeddingArrays[i];

          List<Vector> chunkVectors = [];

          final chunkVector =
              Vector(id: '${txtPath}_$i', values: embeddingArray, metadata: {
            ...chunk.metadata,
            'loc': jsonEncode(chunk.metadata['loc']),
            'pageContent': chunk.pageContent,
            'txtPath': txtPath,
          });

          chunkVectors.add(chunkVector);

          if (chunkVectors.length == batchSize || i == chunks.length - 1) {
            await PineconeClient(
                    apiKey: dotenv.env['PINECONE_API_KEY']!,
                    baseUrl:
                        'https://${index.name}-${index.projectId}.svc.${index.environment}.pinecone.io')
                .upsertVectors(
              indexName: index.name,
              environment: index.environment,
              projectId: index.projectId,
              request: UpsertRequest(vectors: chunkVectors),
            );


            chunkVectors = [];
          }
        }
      }
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Future<String> onImageClick(BuildContext context, CameraDescription firstCamera,ImageLabeler imageLabeler) async{
    final XFile image = await Navigator.push(context,MaterialPageRoute(builder: (context)=>TakePictureScreen(camera: firstCamera,)),);
    for(int i=0;i<10;i++){
    }
    final InputImage inputImage = InputImage.fromFilePath(image.path); 
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    //print(labels.toString());
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DisplayPictureScreen(
          imagePath: image.path,
        ),
      ),
    );
    String ans="func working correctly";
    log(labels.toString());
    //print(labels.length);
    String labelQuery ="";
    for (ImageLabel label in labels) {
      final String text = label.label;
      final double confidence = label.confidence;
      labelQuery+= "{$text:$confidence}";
    }
    String query = "You are an assistant supposed to help with plant disease detection. Using an image labeler, the following labels were obtained $labelQuery. Tell the most likely condition the plant is in. If it is not well, steps to mitigate that.";
    log(query);
    ans = await queryPineConeVectorStore(ServiceConfig.indexName, query);
    log("Answer returned is: $ans");
    return ans;
  }
}
