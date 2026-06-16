import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_app/core/di/service_locator.dart' as di;
import 'package:weather_app/core/theme/weather_theme.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_cubit.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_state.dart';
import 'package:weather_app/features/weather/presentation/pages/weather_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WeatherCubit>(
      create: (_) => di.getIt<WeatherCubit>(),
      child: BlocBuilder<WeatherCubit, WeatherState>(
        builder: (context, state) {
          // Extract weather condition to rebuild dynamic themed profiles
          String condition = 'default';
          if (state is WeatherLoaded) {
            condition = state.weather.conditionText;
          }

          final lightTheme = WeatherThemeBuilder.build(
            condition: condition,
            brightness: Brightness.light,
          );

          final darkTheme = WeatherThemeBuilder.build(
            condition: condition,
            brightness: Brightness.dark,
          );

          return MaterialApp(
            title: 'LumiWeather',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            home: const WeatherPage(),
          );
        },
      ),
    );
  }
}
