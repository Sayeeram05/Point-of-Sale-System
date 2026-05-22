# Waffle Shop Admin UI

A modern, responsive Flutter web application for managing waffle shop operations with a warm, bakery-inspired design aesthetic.

## Features

### 🏠 Home Dashboard
- Welcome screen with waffle shop branding
- Statistics overview cards
- Placeholder areas for future dashboard widgets

### 🧇 Product Management (Main Feature)
- **Category Management**: View, create, edit, and delete waffle categories
- **Product Management**: Manage products within categories
- **Responsive Grid Layout**: Adapts to desktop, tablet, and mobile screens
- **Real-time Statistics**: Live category and product counts
- **Sample Data**: Pre-loaded with realistic waffle categories and products

### 📋 Orders Management
- Coming soon placeholder with planned features
- Future order tracking and management capabilities

## Design System

### 🎨 Waffle Theme
- **Background**: #F5F1E8 (Warm cream)
- **Primary**: #C97B36 (Waffle brown)
- **Secondary**: #F2A65A (Caramel orange)
- **Accent**: #8B5E3C (Coffee brown)
- **Card Background**: #FFF8EE (Light cream)
- **Border**: #E5D3BE (Soft beige)

### 🎯 UI Components
- **WaffleCard**: Reusable card with hover animations
- **WaffleButton**: Themed buttons with multiple variants
- **WaffleBadge**: Price and count badges with rounded styling
- **NavigationShell**: Responsive navigation with mobile support

## Architecture

### 📁 Project Structure
```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── waffle_theme.dart    # Theme configuration
├── widgets/
│   ├── waffle_card.dart     # Reusable card component
│   ├── waffle_button.dart   # Themed button component
│   ├── waffle_badge.dart    # Badge component
│   └── navigation_shell.dart # Main navigation
├── screens/
│   ├── home_screen.dart     # Home dashboard
│   ├── products_screen.dart # Product management
│   └── orders_screen.dart   # Orders placeholder
├── models/
│   ├── category.dart        # Category data model
│   └── product.dart         # Product data model
├── services/
│   ├── base_api_service.dart    # HTTP client
│   ├── category_service.dart    # Category API service
│   └── product_service.dart     # Product API service
└── providers/
    ├── category_provider.dart   # Category state management
    └── product_provider.dart    # Product state management
```

### 🔧 Technology Stack
- **Flutter 3.11.5+**: Cross-platform UI framework
- **Material 3**: Modern design system
- **Provider**: State management
- **HTTP**: API communication
- **Responsive Design**: Mobile-first approach

## Sample Data

### Categories
- **Classic Waffles**: Traditional Belgian and butter waffles
- **Chocolate Waffles**: Decadent chocolate varieties
- **Fruit Waffles**: Fresh fruit toppings
- **Premium Specials**: Gourmet waffle creations

### Products
- Belgian Classic (₹120)
- Choco Lava (₹180)
- Strawberry Cream (₹160)
- Caramel Pecan Royale (₹250)
- And more...

## Backend Integration

### 🔌 API Endpoints
The app is designed to connect to Django REST API endpoints:
- `GET /api/categories/` - List categories
- `POST /api/categories/` - Create category
- `PUT /api/categories/{id}/` - Update category
- `DELETE /api/categories/{id}/` - Delete category
- `GET /api/products/` - List products
- `POST /api/products/` - Create product
- `PUT /api/products/{id}/` - Update product
- `DELETE /api/products/{id}/` - Delete product

### 🎭 Mock Services
Currently uses mock services with realistic data for development and testing.

## Getting Started

### Prerequisites
- Flutter SDK 3.11.5 or higher
- Chrome browser (for web development)

### Installation
1. Navigate to the project directory:
   ```bash
   cd Point-of-Sale-System/owner_ap
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run -d chrome
   ```

### Building for Production
```bash
flutter build web
```

## Responsive Design

### 📱 Breakpoints
- **Mobile**: < 600px (Single column layout)
- **Tablet**: 600px - 1200px (2-3 columns)
- **Desktop**: > 1200px (4 columns)

### 🎨 Animations
- **Card Hover**: Smooth elevation and scale effects
- **Button Interactions**: Color and shadow transitions
- **Page Transitions**: Smooth navigation between screens
- **Loading States**: Skeleton animations during data loading

## Future Enhancements

### 🚀 Planned Features
- **Order Management**: Complete order tracking system
- **Real-time Updates**: WebSocket integration
- **Advanced Analytics**: Sales reports and insights
- **User Authentication**: Admin login system
- **Inventory Management**: Stock tracking
- **Customer Management**: Customer profiles and history

### 🔧 Technical Improvements
- **Property-Based Testing**: Comprehensive test coverage
- **API Integration**: Connect to real Django backend
- **Offline Support**: PWA capabilities
- **Performance Optimization**: Code splitting and lazy loading

## Contributing

This project follows the spec-driven development methodology with comprehensive requirements, design documentation, and implementation tasks.

## License

This project is part of the Point-of-Sale-System and follows the same licensing terms.