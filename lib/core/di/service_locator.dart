import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/weather/data/data_sources/weather_local_data_source.dart';
import 'package:weather_app/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:weather_app/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_last_cached_weather.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_recent_searches.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_weather.dart';
import 'package:weather_app/features/weather/domain/use_cases/save_recent_search.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_cubit.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // Data Sources
  getIt.registerLazySingleton<WeatherRemoteDataSource>(
    () => WeatherRemoteDataSourceImpl(client: getIt()),
  );
  getIt.registerLazySingleton<WeatherLocalDataSource>(
    () => WeatherLocalDataSourceImpl(sharedPreferences: getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton<GetWeatherUseCase>(() => GetWeatherUseCase(getIt()));
  getIt.registerLazySingleton<GetLastCachedWeatherUseCase>(() => GetLastCachedWeatherUseCase(getIt()));
  getIt.registerLazySingleton<GetRecentSearchesUseCase>(() => GetRecentSearchesUseCase(getIt()));
  getIt.registerLazySingleton<SaveRecentSearchUseCase>(() => SaveRecentSearchUseCase(getIt()));

  // Cubits / Blocs (registered as factory since they hold state and should be disposed/recreated)
  getIt.registerFactory<WeatherCubit>(
    () => WeatherCubit(
      getWeatherUseCase: getIt(),
      getLastCachedWeatherUseCase: getIt(),
      getRecentSearchesUseCase: getIt(),
      saveRecentSearchUseCase: getIt(),
    ),
  );
}
