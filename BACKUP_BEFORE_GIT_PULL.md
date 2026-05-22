# 🛡️ Backup Strategy Before Git Pull

## ⚠️ **IMPORTANT: Files Modified for Django-Flutter Connection**

### **Critical Modified Files:**
1. `Backend/Main/settings.py` - **CORS configuration added**
2. `owner_ap/pubspec.yaml` - **HTTP and Provider packages added**
3. `owner_ap/lib/main.dart` - **Complete Flutter app structure**
4. `owner_ap/test/widget_test.dart` - **Updated tests**

### **New Files Created (Safe from git pull):**
- All files in `owner_ap/lib/` folders (config, models, providers, services, theme, widgets, screens)
- `Backend/add_sample_data.py` - Sample data script
- `owner_ap/DJANGO_SETUP.md` - Setup documentation
- `CONNECTION_TEST_REPORT.md` - Test results

## 🔒 **Protection Steps Before Git Pull:**

### Step 1: Backup Critical Files
```bash
# Create backup folder
mkdir -p backup_django_flutter_connection

# Backup Django settings
cp Backend/Main/settings.py backup_django_flutter_connection/settings.py.backup

# Backup Flutter pubspec
cp owner_ap/pubspec.yaml backup_django_flutter_connection/pubspec.yaml.backup

# Backup Flutter main
cp owner_ap/lib/main.dart backup_django_flutter_connection/main.dart.backup
```

### Step 2: Commit Your Changes (Recommended)
```bash
# Add all changes
git add .

# Commit with descriptive message
git commit -m "Add Django-Flutter connection: Waffle Shop Admin UI

- Added CORS configuration to Django settings
- Created complete Flutter web admin UI
- Added HTTP client and Provider state management
- Connected Flutter to Django Category and Product APIs
- Added sample waffle shop data
- Configured responsive design with waffle theme"
```

### Step 3: Safe Git Pull
```bash
# Pull with merge strategy
git pull origin main

# Or pull with rebase to avoid merge commits
git pull --rebase origin main
```

## 🔧 **If Conflicts Occur:**

### Django Settings Conflict:
If `Backend/Main/settings.py` has conflicts, ensure these lines remain:

```python
INSTALLED_APPS = [
    # ... existing apps ...
    'corsheaders',  # Keep this line
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Keep this line at top
    # ... other middleware ...
]

# Keep all CORS settings at the end
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOWED_ORIGINS = [
    "http://localhost:8080",
    "http://localhost:8081", 
    "http://localhost:8082",
]
```

### Flutter pubspec.yaml Conflict:
Ensure these dependencies remain:
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0        # Keep this
  provider: ^6.1.1    # Keep this
  flutter_svg: ^2.0.9 # Keep this
```

## 🚀 **Recovery Commands:**

If connection breaks after git pull:

```bash
# Restore Django CORS settings
cp backup_django_flutter_connection/settings.py.backup Backend/Main/settings.py

# Restore Flutter dependencies  
cp backup_django_flutter_connection/pubspec.yaml.backup owner_ap/pubspec.yaml
cd owner_ap && flutter pub get

# Restart servers
cd Backend && python manage.py runserver &
cd owner_ap && flutter run -d chrome --web-port=8082
```

## ✅ **Verification After Git Pull:**

1. **Check Django CORS:** Look for `corsheaders` in settings.py
2. **Check Flutter deps:** Run `flutter pub get` in owner_ap folder
3. **Test connection:** Run `dart run test_connection.dart`
4. **Start servers:** Django on 8000, Flutter on 8082

## 📋 **Quick Recovery Checklist:**

- [ ] Django server starts without errors
- [ ] Flutter app builds successfully  
- [ ] Categories API returns data: `curl http://localhost:8000/api/category/`
- [ ] Products API returns data: `curl http://localhost:8000/api/products/`
- [ ] Flutter app shows real Django data
- [ ] No CORS errors in browser console

## 🎯 **Bottom Line:**

**The connection will survive git pull IF:**
1. You commit your changes first (recommended)
2. You backup critical files before pulling
3. You resolve any conflicts carefully
4. You restore from backup if needed

**New Flutter files are safe** - they're untracked and won't be affected by git pull.