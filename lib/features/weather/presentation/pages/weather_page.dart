import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  // Determine background gradient based on weather condition text
  List<Color> _getBackgroundGradient(String condition, bool isDark) {
    final cond = condition.toLowerCase();
    
    if (isDark) {
      // Sleek dark modes based on weather condition
      if (cond.contains('sunny') || cond.contains('clear')) {
        return [const Color(0xFF1A1C29), const Color(0xFF233550)]; // Clear Night
      } else if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) {
        return [const Color(0xFF0F1524), const Color(0xFF1D283C)]; // Rainy Night
      } else if (cond.contains('snow') || cond.contains('blizzard') || cond.contains('sleet')) {
        return [const Color(0xFF161E2E), const Color(0xFF2C3E50)]; // Snowy Night
      } else {
        return [const Color(0xFF0F111E), const Color(0xFF1E2235)]; // Cloudy/Default Night
      }
    } else {
      // Warm, vibrant gradients for light mode
      if (cond.contains('sunny') || cond.contains('clear')) {
        return [const Color(0xFFFF8008), const Color(0xFF00C6FF)]; // Warm sunrise
      } else if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) {
        return [const Color(0xFF5B6467), const Color(0xFF8B939A)]; // Misty overcast
      } else if (cond.contains('snow') || cond.contains('blizzard') || cond.contains('sleet')) {
        return [const Color(0xFFE6DADA), const Color(0xFF274046)]; // Ice cold
      } else {
        return [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)]; // Elegant teal/slate
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) {
        // Find a representative weather condition string to shift gradient
        String conditionText = 'default';
        if (state is WeatherLoaded) {
          conditionText = state.weather.conditionText;
        }

        final gradientColors = _getBackgroundGradient(conditionText, isDark);

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
                            _buildHeader(isDark),
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

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.wb_sunny_rounded,
          color: isDark ? const Color(0xFFFFD700) : Colors.white,
          size: 32,
        ),
        const SizedBox(width: 12),
        Text(
          'LUMIWEATHER',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: isDark ? Colors.white : Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
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
        color: theme.brightness == Brightness.dark
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        enabled: !isLoading,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _onSearchSubmitted(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search city...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
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
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'RECENT SEARCHES',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
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
                color: Colors.white.withOpacity(0.15),
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
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      city,
                      style: const TextStyle(
                        color: Colors.white,
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
    return switch (state) {
      WeatherInitial() => _buildWelcomeCard(),
      WeatherLoading() => const GlassCard(child: ShimmerLoading()),
      WeatherLoaded(:final weather, :final isFromCache) => _buildWeatherDetails(weather, isFromCache, theme),
      WeatherError(:final message, :final cachedWeather) => _buildErrorCard(message, cachedWeather, theme),
    };
  }

  Widget _buildWelcomeCard() {
    return const GlassCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_queue_rounded,
              size: 80,
              color: Colors.white70,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to LumiWeather!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter a city name above to view current weather conditions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherEntity weather, bool isFromCache, ThemeData theme) {
    // Standardize URL schema
    final iconUrl = weather.conditionIconUrl.startsWith('http')
        ? weather.conditionIconUrl
        : 'https:${weather.conditionIconUrl}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isFromCache) _buildCacheWarning(weather.lastUpdated),
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
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.wb_cloudy_outlined,
                          size: 64,
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '${weather.temperatureCelsius.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Condition description
                Text(
                  weather.conditionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5EAF5),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Last updated text (only if not showing warning)
                if (!isFromCache)
                  Text(
                    'Last updated: ${_formatTime(weather.lastUpdated)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
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
                    ),
                    _buildDetailItem(
                      icon: Icons.air_rounded,
                      label: 'Wind Speed',
                      value: '${weather.windKph.toStringAsFixed(1)} km/h',
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

  Widget _buildCacheWarning(DateTime lastUpdated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Showing last cached weather from ${_formatTime(lastUpdated)}',
                  style: TextStyle(
                    color: Colors.amber.shade200,
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

  Widget _buildDetailItem({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message, WeatherEntity? cachedWeather, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error Box
        GlassCard(
          opacity: 0.18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        
        // Show cached weather underneath error, if available
        if (cachedWeather != null) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Last Cached Weather:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
