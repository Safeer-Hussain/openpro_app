import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../network/mock_network_interceptor.dart';
import '../network/offline_sync_queue.dart';
import '../network/sync_manager.dart';
import '../notifications/local_notification_service.dart';
import '../../data/repositories/ai_assistant_repository.dart';
import '../../data/repositories/application_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/inmail_repository.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/skill_repository.dart';
import '../../data/repositories/social_repository.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core Singletons
  final database = AppDatabase.instance;
  sl.registerSingleton<AppDatabase>(database);

  final mockInterceptor = MockNetworkInterceptor();
  sl.registerSingleton<MockNetworkInterceptor>(mockInterceptor);

  final apiClient = ApiClient(mockInterceptor: mockInterceptor);
  sl.registerSingleton<ApiClient>(apiClient);

  final notificationService = LocalNotificationService();
  sl.registerSingleton<LocalNotificationService>(notificationService);

  final syncQueue = OfflineSyncQueue(database: database);
  sl.registerSingleton<OfflineSyncQueue>(syncQueue);

  final syncManager = SyncManager(
    queue: syncQueue,
    connectivity: Connectivity(),
  );
  sl.registerSingleton<SyncManager>(syncManager);

  // Repositories
  final jobRepo = JobRepository(database: database);
  sl.registerSingleton<JobRepository>(jobRepo);

  final socialRepo = SocialRepository(database: database);
  sl.registerSingleton<SocialRepository>(socialRepo);

  final communityRepo = CommunityRepository(database: database);
  sl.registerSingleton<CommunityRepository>(communityRepo);

  final profileRepo = ProfileRepository(database: database);
  sl.registerSingleton<ProfileRepository>(profileRepo);

  final skillRepo = SkillRepository(database: database);
  sl.registerSingleton<SkillRepository>(skillRepo);

  final inmailRepo = InmailRepository(database: database);
  sl.registerSingleton<InmailRepository>(inmailRepo);

  final notificationRepo = NotificationRepository(database: database);
  sl.registerSingleton<NotificationRepository>(notificationRepo);

  final applicationRepo = ApplicationRepository(database: database);
  sl.registerSingleton<ApplicationRepository>(applicationRepo);

  final aiRepo = AiAssistantRepository(
    database: database,
    profileRepository: profileRepo,
    jobRepository: jobRepo,
  );
  sl.registerSingleton<AiAssistantRepository>(aiRepo);
}
