# LumiWeather — Weather App with Offline Cache

A premium, highly responsive Flutter Weather Application that displays weather information for cities globally. Designed with clean architectural boundaries, premium glassmorphism aesthetics, dynamic state management, local database caching, search query history, and full offline fallback.

---

## Features

1. **Weather Search by City:** Enter any city name to retrieve details including Temperature, Condition, Humidity, Wind Speed, and the condition-appropriate icon.
2. **Offline Mode & Caching:** 
   - Caches the last successfully loaded city's weather data locally using `SharedPreferences`.
   - If the network becomes unavailable, the app falls back to cached data and displays a prominent warning banner showing "Offline Mode" alongside the timestamp of when the cache was last refreshed.
3. **Recent Searches:**
   - Displays a horizontal list of recently searched cities.
   - Cleans and deduplicates city searches, moving the most recently searched city to the top (maximum of 10 entries).
   - Tapping on a recent search pill automatically runs a new weather query.
4. **Shimmer Loading Skeleton:** Displays a clean skeleton loading visual during network requests to prevent layout jumps and duplicate submissions.
5. **Dynamic Gradient Backgrounds:** The background color shifts depending on the weather conditions (Sunny/Clear, Rain/Drizzle, Snow/Cold, Cloudy/Overcast) for a premium, alive look.
6. **Dark & Light Mode Support:** Fully responsive to system-level light or dark themes, styling cards and typography accordingly.

---

## Architectural Design

The codebase strictly adheres to **Clean Architecture** patterns divided into three distinct conceptual boundaries:

```
lib/
├── core/
│   ├── di/                 # Dependency Injection setup using get_it
│   └── error/              # Failure contracts and ApiResult models
└── features/
    └── weather/
        ├── data/           # JSON Weather Models, Remote HTTP & SharedPreferences Local Data Sources
        ├── domain/         # Pure Dart entities, repository contracts, and use cases (ZERO Flutter imports)
        ├── presentation/   # Cubit state machines, glassmorphic page layouts, and skeleton widgets
```

### 1. Presentation Layer
- **State Management:** Built using `Cubit` (via `flutter_bloc`). The state is modeled using a `sealed class` hierarchy (`WeatherInitial`, `WeatherLoading`, `WeatherLoaded`, `WeatherError`) allowing type-safe exhaustive pattern matching within the UI.
- **Duplicate Request Prevention:** The Cubit verifies the current state and discards search requests if a loading sequence is already in progress.
- **Widgets:** Employs `GlassCard` (a custom glassmorphism implementation using `BackdropFilter` and semi-transparent layers) and customized shimmer loaders.

### 2. Domain Layer (Pure Dart)
- **Purity:** Contains **zero** Flutter imports (purely Dart core code) ensuring maximum maintainability and testability.
- **Repository Interface:** Outlines the core capabilities expected by the app.
- **Use Cases:** Executable wrappers for business transactions (e.g., `GetWeatherUseCase`, `GetRecentSearchesUseCase`, `SaveRecentSearchUseCase`).

### 3. Data Layer
- **Remote Data Source:** Makes REST requests to the WeatherAPI and translates them into model entities.
- **Local Data Source:** Reads/writes cache payloads and recent search lists using `SharedPreferences`.
- **Repository Implementation:** Implements the domain contract. Coordinates the fallback by trying the network first, updating cache on success, and falling back to cache on Socket/Client exceptions.

---

## Setup & Running the Application

This project does not use any code generation library (`build_runner` or `freezed`), allowing instant builds.

### 1. Obtain an API Key
Sign up at [WeatherAPI.com](https://www.weatherapi.com/) for a free account. You will receive an API key instantly from your dashboard.

### 2. Run the App
To protect sensitive credentials (following Rule A.6), the API key is passed dynamically at runtime using `dart-define`:

```bash
flutter run --dart-define=WEATHER_API_KEY=YOUR_WEATHERAPI_KEY
```

Replace `YOUR_WEATHERAPI_KEY` with your actual key from the WeatherAPI dashboard.

---

## Testing

A comprehensive unit test suite is provided to test the business logic, repository coordinates, and state changes.

Run all tests:
```bash
flutter test
```

### Coverage Areas:
- **Cubit states:** Verifies initial states, loading progressions, success caching updates, and error state mapping.
- **Duplicate prevention:** Verifies redundant search queries are ignored if the cubit is in `WeatherLoading`.
- **Repository coordination:** Verifies API data fetch updates local cache on success, and falls back to cache on SocketExceptions (simulated offline mode).
