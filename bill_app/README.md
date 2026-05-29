# bill_app

# Flutter Billing & Stock Management App

A comprehensive tablet-optimized billing and stock management application built with Flutter for shop owners.

## Features

- 📊 **Dashboard**: Real-time daily summary with orders, revenue, and payment tracking
- 🛒 **Order Management**: Create, manage, and customize orders with intuitive UI
- 🍱 **Menu System**: Product catalog with category-wise organization
- 💰 **Payment Processing**: Multiple payment modes (Cash, UPI, Both) with validation
- 🎨 **Customization**: Personalize orders with emojis and colors
- ⚙️ **Settings**: Manage emojis and colors with full CRUD operations
- 📱 **Responsive Design**: Optimized for tablets in both portrait and landscape modes

## Screenshots

The app features a Google Keep-style card layout with smooth animations and intuitive touch controls.

## Requirements

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Backend API server running on `http://127.0.0.1:8000`

## API Endpoints

The app expects the following API endpoints to be available:

### Sales API

- `GET /sales/order/<date>/<date>/` - Get daily summary
- `POST /sales/order/` - Create new order
- `DELETE /sales/order/<order_id>/` - Delete order
- `POST /sales/order/<order_id>/1/` - Mark order complete
- `POST /sales/order/<order_id>/0/` - Mark order incomplete
- `GET /sales/menu/` - Get menu categories and products

### Order Items API

- `POST /sales/orderitem/<order_id>/` - Add product to order
- `POST /sales/orderitem/update/<item_id>/inc/` - Increase quantity
- `POST /sales/orderitem/update/<item_id>/dec/` - Decrease quantity

### User Preferences API

- `GET /user/emojis/` - Get user emojis
- `POST /user/emojis/` - Add emoji
- `DELETE /user/emojis/<id>/` - Delete emoji
- `GET /user/colors/` - Get user colors
- `POST /user/colors/` - Add color
- `DELETE /user/colors/<id>/` - Delete color

## Setup Instructions

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd bill_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Ensure your backend API is running**

   - Start your backend server on `http://127.0.0.1:8000`
   - Verify all required endpoints are available

4. **Run the app**
   ```bash
   flutter run
   ```

## Building

### Debug Build

```bash
flutter build apk --debug
```

### Release Build

```bash
flutter build apk --release
```

### For specific platforms

```bash
# Android
flutter build apk

# iOS (requires macOS)
flutter build ios

# Web
flutter build web

# Windows (requires Windows)
flutter build windows

# Linux (requires Linux)
flutter build linux

# macOS (requires macOS)
flutter build macos
```

## Testing

Run the test suite:

```bash
flutter test
```

Check for code issues:

```bash
flutter analyze
```

## Architecture

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── order.dart           # Order and OrderItem models
│   ├── menu.dart            # Menu, Category, Product models
│   └── user_preferences.dart # UserEmoji and UserColor models
├── services/                 # Business logic
│   ├── api_service.dart     # HTTP API calls
│   └── app_colors.dart      # Color utilities
├── pages/                    # Screen widgets
│   ├── dashboard_page.dart  # Main dashboard
│   ├── menu_page.dart       # Order creation/menu
│   └── settings_page.dart   # Settings management
└── widgets/                  # Reusable components
    ├── order_card.dart      # Order display card
    ├── order_detail_dialog.dart # Order details popup
    └── emoji_color_dialog.dart  # Customization dialog
```

## Key Features

### Tablet-First Design

- Optimized layouts for both portrait and landscape orientations
- Large touch targets for better usability
- Responsive grid systems that adapt to screen size

### Smooth Animations

- Google Keep-style staggered entry animations
- Smooth page transitions
- Real-time UI updates with visual feedback

### Intuitive Interactions

- Tap to add items, long press to remove
- Pull-to-refresh on dashboard
- Visual quantity indicators (badges)
- Touch-friendly payment mode selection

### Robust Error Handling

- Graceful handling of network errors
- User-friendly error messages
- Retry mechanisms for failed operations
- Proper loading states throughout the app

## Configuration

### API Base URL

The API base URL is configured in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

Update this URL to match your backend server configuration.

## Troubleshooting

### Common Issues

1. **API Connection Failed**

   - Ensure your backend server is running
   - Check the API base URL configuration
   - Verify network connectivity

2. **Build Errors**

   - Run `flutter clean` and `flutter pub get`
   - Check Flutter and Dart SDK versions
   - Verify all dependencies are compatible

3. **Performance Issues**
   - Ensure you're running in release mode for production
   - Check for memory leaks in animations
   - Monitor network request frequency

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure they pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.
