# 📱 Eternal Scan

> AI-powered grocery scanner for the Eternal (Blinkit) iOS Hackathon.

## 🎯 Vision

Enable users to refill groceries in one action.

```
Action Button / App Launch
        ↓
   Open Camera
        ↓
 Scan Grocery Product
        ↓
 Vision OCR + AI Recognition
        ↓
 Match Product
        ↓
 Add to Cart
        ↓
    Checkout
```

---

# 🛠 Tech Stack

- Swift 6
- SwiftUI
- iOS 18+
- Observation (`@Observable`)
- MVVM
- Clean Architecture
- Dependency Injection
- AVFoundation
- Vision Framework
- App Intents
- Async/Await

---

# 🏗 Architecture

```
View
   ↓
ViewModel
   ↓
UseCase (Future)
   ↓
Repository (Future)
   ↓
Service
```

All dependencies are managed by **AppContainer**.

---

# 📂 Project Structure

```
App
├── EternalScanApp
├── AppContainer
├── AppRouter
├── RootView

Core
├── Camera
├── Vision
├── AI
├── Networking
├── Storage
└── DesignSystem

Features
├── Home
├── Scanner
├── Processing
├── Result
└── Cart
```

---

# 🚀 Sprint Roadmap

## ✅ Sprint 1 – Foundation

### Goal
Build the project architecture.

### Deliverables

- AppContainer
- Dependency Injection
- Navigation
- AppRouter
- RootView
- MVVM Setup
- Folder Structure

---

## ✅ Sprint 2 – Camera Preview

### Goal
Display a live native camera preview.

### Deliverables

- Camera Permission
- AVCaptureSession
- CameraService
- Preview Layer
- CameraPreview
- Scanner Screen

---

## 🚧 Sprint 3 – Photo Capture

### Goal
Capture an image from the camera.

### Deliverables

- AVCapturePhotoOutput
- Capture Button
- Photo Capture Processor
- Async `capturePhoto()`
- UIImage Pipeline
- Haptic Feedback
- Image Orientation Fix

Output

```
Camera
    ↓
UIImage
```

---

## 📖 Sprint 4 – Vision OCR

### Goal
Extract useful information from the captured image.

### Deliverables

- Vision Framework
- Text Recognition
- Barcode Detection
- OCRResult
- Confidence Score

Output

```
UIImage
    ↓
OCRResult
```

---

## 🤖 Sprint 5 – AI Recognition

### Goal
Convert OCR into an actual product.

### Deliverables

- AIService
- Product Recognition
- Brand Detection
- Variant Detection
- Size Detection
- Confidence Ranking

Output

```
OCRResult
      ↓
RecognizedProduct
```

---

## 🛒 Sprint 6 – Product Matching

### Goal
Match the recognized product with the Eternal catalog.

### Deliverables

- Catalog Search
- Exact Match
- Fuzzy Match
- Product Ranking
- Product Details

Output

```
RecognizedProduct
        ↓
Catalog Product
```

---

## 💳 Sprint 7 – Cart

### Goal
Prepare shopping flow.

### Deliverables

- Add to Cart
- Quantity Selection
- Cart Screen
- Checkout Flow

Output

```
Catalog Product
        ↓
Cart
```

---

## ⚡ Sprint 8 – Action Button

### Goal
Launch scanning with one press.

### Deliverables

- App Intents
- Apple Shortcuts
- Action Button Support
- Deep Linking

Output

```
Action Button
      ↓
Camera
```

---

## ✨ Sprint 9 – Polish

### Goal
Production-ready experience.

### Deliverables

- Tap to Focus
- Pinch to Zoom
- Flash
- Torch
- Camera Switching
- Loading States
- Error Handling
- Animations
- Accessibility
- Performance Optimization

---

# 📌 Coding Principles

- MVVM
- Clean Architecture
- Protocol-Oriented
- Dependency Injection
- Async/Await First
- No Singleton
- No ObservableObject
- No EnvironmentObject
- Views never create ViewModels
- ViewModels never create Services
- Production-quality code from Day One

---

# 🎯 Final User Journey

```
Home
   ↓
Action Button
   ↓
Camera Preview
   ↓
Capture Photo
   ↓
Vision OCR
   ↓
AI Recognition
   ↓
Catalog Matching
   ↓
Add to Cart
   ↓
Checkout
```

---

# ✅ Milestone Checklist

- [x] Foundation
- [x] Live Camera Preview
- [ ] Photo Capture
- [ ] OCR
- [ ] AI Recognition
- [ ] Product Matching
- [ ] Cart
- [ ] Action Button
- [ ] Production Polish