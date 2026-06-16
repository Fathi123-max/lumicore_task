import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_recent_searches.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_weather.dart';
import 'package:weather_app/features/weather/domain/use_cases/save_recent_search.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_state.dart';

class WeatherCubit extends Cubit<WeatherState> {
  final GetWeatherUseCase getWeatherUseCase;
  final GetRecentSearchesUseCase getRecentSearchesUseCase;
  final SaveRecentSearchUseCase saveRecentSearchUseCase;

  WeatherCubit({
    required this.getWeatherUseCase,
    required this.getRecentSearchesUseCase,
    required this.saveRecentSearchUseCase,
  }) : super(const WeatherInitial(recentSearches: [])) {
    initApp();
  }

  Future<void> initApp() async {
    final recentResult = await getRecentSearchesUseCase();
    final searches = switch (recentResult) {
      ApiResultSuccess(:final data) => data,
      ApiResultFailure() => const <String>[],
    };

    if (searches.isNotEmpty) {
      emit(WeatherLoading(recentSearches: searches));
      final result = await getWeatherUseCase(searches.first);
      switch (result) {
        case ApiResultSuccess(:final data):
          emit(WeatherLoaded(
            weather: data,
            recentSearches: searches,
            isFromCache: data.isCached,
          ));
        case ApiResultFailure(:final failure):
          emit(WeatherError(
            message: failure.message,
            recentSearches: searches,
          ));
      }
    } else {
      emit(WeatherInitial(recentSearches: searches));
    }
  }

  Future<void> fetchWeather(String cityName) async {
    // Prevent duplicate requests
    if (state is WeatherLoading) return;

    final trimmed = cityName.trim();
    if (trimmed.isEmpty) {
      emit(WeatherError(
        message: 'City name cannot be empty.',
        recentSearches: state.recentSearches,
      ));
      return;
    }

    final previousSearches = state.recentSearches;
    emit(WeatherLoading(recentSearches: previousSearches));

    final result = await getWeatherUseCase(trimmed);

    switch (result) {
      case ApiResultSuccess(:final data):
        // Save to recent searches if search was successful and not loaded from cache
        if (!data.isCached) {
          await saveRecentSearchUseCase(data.cityName);
        }
        
        // Fetch updated recent searches
        final recentResult = await getRecentSearchesUseCase();
        final updatedSearches = switch (recentResult) {
          ApiResultSuccess(:final data) => data,
          ApiResultFailure() => previousSearches,
        };

        emit(WeatherLoaded(
          weather: data,
          recentSearches: updatedSearches,
          isFromCache: data.isCached,
        ));

      case ApiResultFailure(:final failure):
        emit(WeatherError(
          message: failure.message,
          recentSearches: previousSearches,
        ));
    }
  }
}
