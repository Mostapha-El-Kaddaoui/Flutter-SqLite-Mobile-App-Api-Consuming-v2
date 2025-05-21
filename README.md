# LKBooks-v2 - Flutter Book Catalog App

A Flutter mobile application that displays a catalog of books by consuming the Google Books API. The app features a responsive grid layout, elegant UI with consistent styling, and network data fetching.

## Features

- **API Integration**: Fetches book data from Google Books API
- **Responsive UI**: Displays books in a 2-column grid layout
- **Elegant Design**: Uses Google Fonts and consistent styling
- **App Drawer**: Navigation drawer with user profile section
- **Loading States**: Proper handling of loading, error, and empty states

## App Architecture

The application follows a simple structure:

- **main.dart**: Contains the UI implementation and the app entry point
- **book.dart**: Defines the Book model class for parsing API responses
- **db_service.dart**: Handles API requests to the Google Books service

## Technical Implementation

### Dependencies

- `flutter`: SDK for building cross-platform applications
- `google_fonts`: For typography
- `http`: For API requests

### API Integration

The app fetches book data from the Google Books API. Each book is displayed with:
- Title
- Thumbnail image
- Star rating
- Price
- "More" button for additional details

### UI Components

- **AppBar**: Custom app bar with the title "Mohammedia NEWs"
- **Navigation Drawer**: Side menu with home, books, and favorites options
- **Book Cards**: Individual cards displaying book information
- **Grid Layout**: Responsive 2-column layout for displaying books

## Getting Started

1. Ensure you have Flutter installed on your machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the application

## Future Improvements

- Implement book details page
- Add search functionality
- Implement favorites system
- Fix thumbnail image loading issues
- Add pagination for API results

## Screenshots

![image](https://github.com/user-attachments/assets/45d555d1-4194-4615-8caf-2dabc70f1562)
![image](https://github.com/user-attachments/assets/111a3c28-1371-4871-a440-4b65fc0405c1)
![image](https://github.com/user-attachments/assets/fc2a40a2-f153-4307-830a-71bf6b20fd07)


## License

© 2023 - All rights reserved 
