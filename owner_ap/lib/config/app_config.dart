/// Application configuration for API endpoints and service selection
class AppConfig {
  // API Configuration - Using HTTP for development (HTTPS requires SSL certificates)
  static const String djangoBaseUrl = 'http://localhost:8001/api';
  static const bool useMockServices = false; // Using Django API
  
  // Development settings
  static const bool enableDebugLogs = true;
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // UI Configuration
  static const bool enableAnimations = true;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // Feature flags
  static const bool enableOrderManagement = true; // Now enabled
  static const bool enableRealTimeUpdates = false; // Future feature
}