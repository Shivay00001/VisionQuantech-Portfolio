rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper function
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Course Thumbnails - Public Read, Admin Write
    match /course_thumbnails/{filename} {
      allow read: if true; // Public read for thumbnails
      allow write: if false; // Only admins via backend
    }
    
    // User Uploads - Private
    match /user_uploads/{userId}/{filename} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow write: if isAuthenticated() && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
    
    // Profile Pictures
    match /profile_pictures/{userId} {
      allow read: if true; // Public read
      allow write: if isAuthenticated() && request.auth.uid == userId
                   && request.resource.size < 2 * 1024 * 1024; // 2MB limit
    }
    
    // Default deny
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}