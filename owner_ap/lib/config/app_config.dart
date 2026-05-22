/// Application configuration for API endpoints and service selection
class AppConfig {
  // API Configuration
  static const String djangoBaseUrl = 'http://localhost:8000/api';
  static const bool useMockServices = false; // Changed to false - now using Django API!
  
  // Development settings
  static const bool enableDebugLogs = true;
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // UI Configuration
  static const bool enableAnimations = true;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // Feature flags
  static const bool enableOrderManagement = false; // Coming soon
  static const bool enableRealTimeUpdates = false; // Future feature
}