import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_app/core/theme/weather_theme.dart';
import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_cubit.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_state.dart';
import 'package:weather_app/features/weather/presentation/widgets/glass_card.dart';
import 'package:weather_app/features/weather/presentation/widgets/shimmer_loading.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted() {
    final city = _searchController.text;
    if (city.isNotEmpty) {
      context.read<WeatherCubit>().fetchWeather(city);
      _searchFocusNode.unfocus();
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';
    
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(localDateTime.year, localDateTime.month, localDateTime.day);
    
    if (dateToCheck == today) {
      return timeStr;
    } else {
      final difference = today.difference(dateToCheck).inDays;
      if (difference == 1) {
        return 'Yesterday at $timeStr';
      } else if (difference > 1 && difference <= 7) {
        return '$difference days ago at $timeStr';
      } else {
        final day = localDateTime.day.toString().padLeft(2, '0');
        final month = localDateTime.month.toString().padLeft(2, '0');
        return '$day/$month/${localDateTime.year} at $timeStr';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weatherTheme = theme.extension<WeatherThemeExtension>();

    // Fallback gradient in case theme extension is not set
    final fallbackGradient = theme.brightness == Brightness.dark
        ? const [Color(0xFF0F111E), Color(0xFF1E2235)]
        : const [Color(0xFFE0F7FA), Color(0xFF80DEEA)];

    final gradientColors = weatherTheme?.gradientColors ?? fallbackGradient;

    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                color: theme.colorScheme.primary,
                backgroundColor: theme.scaffoldBackgroundColor,
                onRefresh: () async {
                  if (state is WeatherLoaded) {
                    await context.read<WeatherCubit>().fetchWeather(state.weather.cityName);
                  } else if (state is WeatherError && state.cachedWeather != null) {
                    await context.read<WeatherCubit>().fetchWeather(state.cachedWeather!.cityName);
                  }
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Styled App Header
                            _buildHeader(theme),
                            const SizedBox(height: 24),

                            // Search bar
                            _buildSearchBar(theme, state is WeatherLoading),
                            const SizedBox(height: 16),

                            // Recent Searches
                            _buildRecentSearches(state.recentSearches, theme),
                            const SizedBox(height: 24),

                            // Weather Content
                            Expanded(
                              child: _buildWeatherContent(state, theme),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.wb_sunny_rounded,
          color: theme.brightness == Brightness.dark ? const Color(0xFFFFD700) : theme.colorScheme.primary,
          size: 32,
        ),
        const SizedBox(width: 12),
        Text(
          'LUMIWEATHER',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: theme.colorScheme.onSurface,
            shadows: [
              Shadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        enabled: !isLoading,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _onSearchSubmitted(),
        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search city...',
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          suffixIcon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  onPressed: _onSearchSubmitted,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(List<String> searches, ThemeData theme) {
    if (searches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'RECENT SEARCHES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: searches.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final city = searches[index];
              return Material(
                color: theme.colorScheme.surface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _searchController.text = city;
                    context.read<WeatherCubit>().fetchWeather(city);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      city,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherContent(WeatherState state, ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (state) {
        WeatherInitial() => _buildWelcomeCard(theme, key: const ValueKey('welcome')),
        WeatherLoading() => const GlassCard(
            key: ValueKey('loading'),
            child: ShimmerLoading(),
          ),
        WeatherLoaded(:final weather, :final isFromCache) => _buildWeatherDetails(
            weather,
            isFromCache,
            theme,
            key: const ValueKey('loaded'),
          ),
        WeatherError(:final message, :final cachedWeather) => _buildErrorCard(
            message,
            cachedWeather,
            theme,
            key: const ValueKey('error'),
          ),
      },
    );
  }

  Widget _buildWelcomeCard(ThemeData theme, {Key? key}) {
    return GlassCard(
      key: key,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_queue_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to LumiWeather!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a city name above to view current weather conditions.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherEntity weather, bool isFromCache, ThemeData theme, {Key? key}) {
    // Standardize URL schema
    final iconUrl = weather.conditionIconUrl.startsWith('http')
        ? weather.conditionIconUrl
        : 'https:${weather.conditionIconUrl}';

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isFromCache) _buildCacheWarning(weather.lastUpdated, theme),
        const SizedBox(height: 8),
        Expanded(
          child: GlassCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // City Name
                Text(
                  weather.cityName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Icon and Temperature
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (weather.conditionIconUrl.isNotEmpty)
                      Image.network(
                        iconUrl,
                        width: 76,
                        height: 76,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.wb_cloudy_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '${weather.temperatureCelsius.toStringAsFixed(1)}°C',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w200,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Condition description
                Text(
                  weather.conditionText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Last updated text (only if not showing warning)
                if (!isFromCache)
                  Text(
                    'Last updated: ${_formatTime(weather.lastUpdated)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),

                const SizedBox(height: 32),

                // Detail Metrics Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDetailItem(
                      icon: Icons.water_drop_rounded,
                      label: 'Humidity',
                      value: '${weather.humidity}%',
                      theme: theme,
                    ),
                    _buildDetailItem(
                      icon: Icons.air_rounded,
                      label: 'Wind Speed',
                      value: '${weather.windKph.toStringAsFixed(1)} km/h',
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCacheWarning(DateTime lastUpdated, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: theme.colorScheme.tertiary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Showing last cached weather from ${_formatTime(lastUpdated)}',
                  style: TextStyle(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message, WeatherEntity? cachedWeather, ThemeData theme, {Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error Box
        GlassCard(
          opacity: 0.18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        
        // Show cached weather underneath error, if available
        if (cachedWeather != null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Last Cached Weather:',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _buildWeatherDetails(cachedWeather, true, theme),
          ),
        ],
      ],
    );
  }
}
