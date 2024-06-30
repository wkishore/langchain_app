import 'package:langchain_app/config/config.dart';
import 'package:langchain_app/services/langchain/langchain_services_implementation.dart';
//import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'query_notifier.g.dart';

enum QueryEnum{
  initial,
  loading,
  loaded,
  error,
}

class QueryState{
  final String result;
  final QueryEnum state;

  QueryState({
    required this.result,
    required this.state,
  });

  QueryState copyWith({
    String? result,
    QueryEnum? state,
  }){
    return QueryState(result: result ?? this.result, state: state ?? this.state);
  }
}

@riverpod
class QueryNotifier extends _$QueryNotifier{
  @override
  QueryState build()=> QueryState(result: '', state: QueryEnum.initial);

  void queryPineConeIndex(String query) async{
    state = QueryState(result: '', state: QueryEnum.loading);
    try {
      final result = await ref.read(langchainServiceProvider).queryPineConeVectorStore(ServiceConfig.indexName, query);
      state = QueryState(result: result, state: QueryEnum.loaded);
    } catch (e) {
      state = QueryState(result: '', state: QueryEnum.error);
    }
  }
}