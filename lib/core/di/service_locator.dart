import 'package:get_it/get_it.dart';
import '../websocket/gateway_client.dart';
import '../storage/local_storage.dart';
import '../notifications/notification_service.dart';
import '../../features/search/service/message_search_service.dart';

/// 服务定位器 - 全局依赖注入容器
/// 
/// 使用 GetIt 实现单例模式，统一管理所有依赖
final getIt = GetIt.instance;

/// 初始化所有依赖
Future<void> setupDependencies() async {
  // 核心服务 - 单例
  getIt.registerLazySingleton<GatewayClient>(() => GatewayClient());
  
  getIt.registerLazySingletonAsync<LocalStorage>(() async {
    final storage = LocalStorage();
    await storage.initialize();
    return storage;
  });
  
  getIt.registerLazySingleton<NotificationService>(() {
    final service = NotificationService();
    service.initialize();
    return service;
  });
  
  // 搜索服务 - 需要等待 LocalStorage 初始化
  getIt.registerLazySingletonAsync<MessageSearchService>(() async {
    final storage = await getIt.getAsync<LocalStorage>();
    return MessageSearchService(storage: storage);
  });
}

/// 重置所有依赖（用于测试）
void resetDependencies() {
  getIt.reset();
}
