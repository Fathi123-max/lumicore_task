Flutter Developer Assessment
Project: Weather App with Offline Cache
Overview
Build a Flutter application that allows users to search for weather information by city name, view current weather details, and access the last-viewed weather data even when offline.
The purpose of this assessment is to evaluate your Flutter development skills, including architecture, networking, local data storage, error handling, and asynchronous programming.
Objectives
Develop a weather application that:
Searches weather information by city name
Retrieves weather data from a public weather API
Stores recent searches locally
Supports offline access to the last-viewed weather data
Handles loading and error states properly
Uses a clean and scalable architecture
Functional Requirements
1. Search Weather by City
Users should be able to:
Enter a city name
Submit a search request
View current weather information
Display at Minimum
City Name
Temperature
Weather Condition
Humidity
Wind Speed
2. Weather API Integration
Use one of the following APIs:
Option 1
OpenWeather API
Option 2
WeatherAPI
The application should:
Make asynchronous API requests
Parse API responses correctly
Handle API failures gracefully
3. Offline Cache Support
The application must support offline access.
Requirements
Save the most recently viewed weather data locally
If the device has no internet connection:
Display the last-viewed weather data
Clearly indicate that cached data is being shown
Suggested Storage Solutions
Hive
SharedPreferences
Isar
SQLite
Any suitable local storage solution is acceptable.
4. Recent Searches
Maintain a list of recent city searches.
Requirements
Save recent searches locally
Display recent searches on the UI
Allow users to tap a recent search to reload weather information
5. Loading State
While data is being fetched:
Show shimmer loading UI
Prevent duplicate requests
6. Error Handling
Handle the following scenarios:
Invalid City Name
Example:
User enters an unknown city
Expected:
Show a meaningful error message
Network Failure
Example:
No internet connection
Expected:
Display cached data if available
Show a user-friendly error message
API Failure
Example:
Server error
Rate limiting
Expected:
Display appropriate feedback to the user
7. Pull-to-Refresh
Implement pull-to-refresh functionality.
Expected behavior:
Refresh weather information from the API
Update cached data after a successful refresh
Technical Requirements
Architecture
Use the Repository Pattern.
State Management
Any of the following is acceptable:
Bloc / Cubit
Riverpod
Provider
Other justified approaches
The chosen solution should be clean and maintainable.
Assessment Areas
The assessment will focus on:
Networking
API integration
Request handling
Response parsing
Error Handling
User-friendly messages
Exception management
Edge-case handling
Caching
Local storage implementation
Offline support
Architecture
Repository pattern
Separation of concerns
Code organization
Async Programming
Efficient asynchronous operations
State updates during async tasks
Bonus Points
The following are optional but will be considered positively:
Unit Tests
Dark Mode Support
Clean Architecture
Weather Icons and Visual Enhancements
Deliverables
Please submit:
Source Code Repository (GitHub/GitLab/Bitbucket)
README.md containing:
Setup instructions
Architecture explanation
APK build
screen recording
Submission Deadline
One Week From now. Send an email to orbin.ahmed@lumicore.ae with submission deliverables. If you have any questions or queries feel free to reach out as well.
Good luck!


