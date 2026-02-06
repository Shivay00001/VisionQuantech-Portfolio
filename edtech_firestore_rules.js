rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper Functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function hasEnrollment(courseId) {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/purchases/$(request.auth.uid + '_' + courseId));
    }
    
    // Users Collection
    match /users/{userId} {
      // Users can only read/write their own document
      allow read: if isOwner(userId);
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if false; // Prevent deletion
    }
    
    // Courses Collection
    match /courses/{courseId} {
      // Anyone authenticated can read course list
      allow read: if isAuthenticated();
      // Only admins can write (implement admin check in production)
      allow write: if false;
    }
    
    // Lessons Collection - CRITICAL SECURITY
    match /lessons/{lessonId} {
      // Can only read lesson if:
      // 1. User is authenticated
      // 2. User has purchased the course
      allow read: if isAuthenticated() && 
                     hasEnrollment(resource.data.courseId);
      
      // Only admins can write
      allow write: if false;
    }
    
    // Purchases Collection
    match /purchases/{purchaseId} {
      // Users can only read their own purchases
      allow read: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
      
      // Users can create their own purchase records
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      
      // Prevent updates and deletes (unless admin)
      allow update, delete: if false;
    }
    
    // Analytics Collection (Optional)
    match /analytics/{document=**} {
      allow read: if false; // Only backend can read
      allow write: if isAuthenticated(); // Users can write their own analytics
    }
    
    // Default deny all
    match /{document=**} {
      allow read, write: if false;
    }
  }
}