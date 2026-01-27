class DistanceCalculator {
  // Average real-world heights in meters
  static const Map<String, double> _objectHeights = {
    'person': 1.7,
    'chair': 0.9,
    'table': 0.75,
    'door': 2.0,
    'couch': 0.85,
    'car': 1.5,
    'bicycle': 1.1,
    'bench': 0.8,
    'bed': 0.6,
    'cabinet': 1.8,
    'stairs': 1.0,
    'obstacle': 0.5,
  };
  
  // Camera focal length estimation (typical smartphone)
  static const double _focalLength = 700.0;
  
  /// Estimates distance to object based on bounding box height
  /// 
  /// Uses pinhole camera model:
  /// distance = (real_height * focal_length) / pixel_height
  static double estimate(double pixelHeight, String objectLabel) {
    // Get real-world height of object
    final realHeight = _getRealHeight(objectLabel);
    
    // Avoid division by zero
    if (pixelHeight < 1) {
      return 10.0; // Return max distance
    }
    
    // Calculate distance using pinhole camera model
    double distance = (realHeight * _focalLength) / pixelHeight;
    
    // Clamp distance between 0.3m and 10m
    distance = distance.clamp(0.3, 10.0);
    
    return distance;
  }
  
  /// Gets the real-world height of an object
  static double _getRealHeight(String label) {
    // Normalize label to lowercase
    final normalizedLabel = label.toLowerCase();
    
    // Check if we have a predefined height
    for (var entry in _objectHeights.entries) {
      if (normalizedLabel.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default height for unknown objects
    return 1.0;
  }
  
  /// Estimates distance using width (alternative method)
  static double estimateByWidth(
    double pixelWidth,
    String objectLabel,
    double imageWidth,
  ) {
    // Average real-world widths
    final Map<String, double> widths = {
      'person': 0.5,
      'chair': 0.5,
      'table': 1.2,
      'door': 0.9,
      'car': 1.8,
      'stairs': 1.0,
      'obstacle': 0.6,
    };
    
    final realWidth = widths[objectLabel.toLowerCase()] ?? 0.6;
    
    if (pixelWidth < 1) return 10.0;
    
    double distance = (realWidth * _focalLength) / pixelWidth;
    return distance.clamp(0.3, 10.0);
  }
  
  /// Combines height and width estimation for better accuracy
  static double estimateCombined(
    double pixelHeight,
    double pixelWidth,
    String objectLabel,
    double imageWidth,
  ) {
    final heightDistance = estimate(pixelHeight, objectLabel);
    final widthDistance = estimateByWidth(pixelWidth, objectLabel, imageWidth);
    
    // Average the two estimates
    return (heightDistance + widthDistance) / 2;
  }
}