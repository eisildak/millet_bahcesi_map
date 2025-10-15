# Flutter Kurulum Rehberi

## macOS İçin Flutter Kurulumu

### 1. Flutter SDK İndir
```bash
# Flutter'ı indir
curl -o flutter_macos_3.16.0-stable.zip https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.16.0-stable.zip

# Arşivi aç
unzip flutter_macos_3.16.0-stable.zip

# Ana dizine taşı
sudo mv flutter /usr/local/flutter
```

### 2. PATH'e Ekle
```bash
# .zshrc dosyasını düzenle
nano ~/.zshrc

# Şu satırı ekle:
export PATH="$PATH:/usr/local/flutter/bin"

# Terminal'i yeniden başlat veya:
source ~/.zshrc
```

### 3. Flutter Doctor Çalıştır
```bash
flutter doctor
```

### 4. Xcode ve Android Studio Kur
- **Xcode**: App Store'dan indirin
- **Android Studio**: https://developer.android.com/studio

### 5. Flutter Konfigürasyonu
```bash
# iOS simulator için
flutter config --enable-ios

# Android için
flutter config --android-studio-dir /Applications/Android\ Studio.app/Contents
```

## Hızlı Kurulum (Homebrew ile)
```bash
# Homebrew yükle (yoksa)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutter'ı kur
brew install --cask flutter

# Flutter doctor çalıştır
flutter doctor
```

## Proje Çalıştırma
```bash
cd /Users/pointr/Documents/repository/millet_bahcesi_map

# Bağımlılıkları yükle
flutter pub get

# JSON serializasyon dosyalarını oluştur
flutter packages pub run build_runner build

# iOS simulator'da çalıştır
flutter run -d ios

# Android emulator'da çalıştır
flutter run -d android
```

## Gerekli Bağımlılıklar
- Xcode (iOS için)
- Android Studio (Android için)
- CocoaPods (iOS dependencies için)

```bash
# CocoaPods kur
sudo gem install cocoapods
```