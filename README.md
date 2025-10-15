# 🎓 Unified Campus

A comprehensive Flutter-based campus management system that connects students and professors through an integrated platform for academic activities, document management, and community interaction.
Anyone willing to add improvements is welcomed.
## ✨ Features

### 👨‍🎓 Student Features
- **Document Management**: Upload, track, and manage academic documents with approval workflow
- **Query System**: Submit academic queries to professors with real-time status tracking
- **Community Chat**: Join class communities and interact with peers and professors
- **Notifications**: Real-time notifications for document approvals, query responses, and community activities
- **Subject Access**: Browse and access subject-specific content and materials

### 👨‍🏫 Professor Features
- **Document Approval**: Review and approve/reject student-uploaded documents
- **Query Management**: Respond to student queries and provide academic guidance
- **Subject Management**: Create and manage subjects, content, and academic years
- **Community Administration**: Create and manage class communities with member control
- **Student Oversight**: View student lists, track submissions, and monitor academic progress
- **Notification System**: Send targeted notifications to students

### 🔄 Shared Features
- **Real-time Chat**: Enhanced community chat with image sharing and message management
- **Firebase Integration**: Secure authentication and real-time data synchronization
- **Cross-platform**: Works on Android, iOS, and Web
- **Dark/Light Themes**: Adaptive UI with role-based theming
- **File Management**: Support for PDFs, images, and various document formats

## 🛠️ Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage, Cloud Messaging)
- **State Management**: Provider
- **File Handling**: Syncfusion PDF Viewer, File Picker
- **Notifications**: Firebase Cloud Messaging, Flutter Local Notifications
- **Storage**: Firebase Storage with Cloudinary integration

## 📱 Screenshots & UI

The app features a modern, intuitive interface with:
- Role-based navigation and theming
- Responsive design for all screen sizes
- Material Design 3 components
- Smooth animations and transitions

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Firebase project setup
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Unified-Campus
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add Android/iOS apps to your Firebase project
   - Download and place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication, Firestore, Storage, and Cloud Messaging

4. **Configure Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── core/
│   ├── widgets/          # Reusable UI components
│   ├── constants.dart    # App constants
│   └── themes.dart       # Theme configurations
├── models/               # Data models
├── providers/            # State management
├── screens/
│   ├── auth/            # Authentication screens
│   ├── common/          # Shared screens
│   ├── professor/       # Professor-specific screens
│   └── student/         # Student-specific screens
├── services/
│   ├── auth_service.dart      # Authentication logic
│   ├── firestore_service.dart # Database operations
│   ├── notification_service.dart # Push notifications
│   └── storage_service.dart   # File storage
├── utils/               # Helper functions
├── app.dart            # App configuration
└── main.dart           # Entry point
```

## 🔧 Configuration

### Firebase Configuration
1. **Authentication**: Email/Password authentication enabled
2. **Firestore**: Structured collections for users, documents, queries, communities
3. **Storage**: File upload with security rules
4. **Cloud Messaging**: Push notifications for real-time updates

### Environment Setup
- Update `firestore.rules` with your security requirements
- Configure notification settings in `firebase/messaging.js`
- Set up Cloudinary credentials for enhanced file management

## 📋 Key Collections (Firestore)

- **users**: User profiles with role-based access
- **documents**: Document management with approval workflow
- **queries**: Student-professor query system
- **communities**: Class communities and chat messages
- **subjects**: Academic subject management
- **notifications**: Real-time notification system

## 🔐 Security Features

- Role-based access control (Student/Professor)
- Secure file upload with validation
- Firebase Security Rules implementation
- User authentication and session management
- Data encryption and secure communication

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation in `/docs`

## 🔄 Version History

- **v1.0.0**: Initial release with core features
  - User authentication and role management
  - Document upload and approval system
  - Query management system
  - Community chat functionality
  - Real-time notifications

## 🎯 Future Enhancements

- [ ] Video conferencing integration
- [ ] Assignment submission system
- [ ] Grade management
- [ ] Calendar integration
- [ ] Mobile app optimization
- [ ] Advanced analytics dashboard

---

**Built with ❤️ using Flutter and Firebase**
