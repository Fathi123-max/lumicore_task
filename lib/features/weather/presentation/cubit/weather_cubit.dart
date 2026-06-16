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
    loadRecentSearches();
    fetchWeather('Dubai');
  }

  Future<void> loadRecentSearches() async {
    final result = await getRecentSearchesUseCase();
    switch (result) {
      case ApiResultSuccess(:final data):
        emit(WeatherInitial(recentSearches: data));
      case ApiResultFailure():
        emit(WeatherInitial(recentSearches: state.recentSearches));
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
