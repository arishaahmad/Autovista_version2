import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../models/car_model.dart';
import '../models/document_model.dart';
import '../models/parking_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart' as app_models;
import 'package:logger/logger.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // Authentication methods
  Future<String> registerUser(
    String name,
    String email,
    String password,
    String location, {
    String? licenseStartDate,
    int? licenseValidityMonths,
  }) async {
    try {
      // Create user in Supabase Auth
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      // Create user profile in Supabase
      await supabase.from('users').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'location': location,
        'license_start_date': licenseStartDate,
        'license_validity_months': licenseValidityMonths,
        'created_at': DateTime.now().toIso8601String(),
      });

      return response.user!.id;
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  Future<String> loginUser(String email, String password) async {
    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to login');
      }

      return response.user!.id;
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Helper method to get current user
  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }

  // Helper method to check if user is logged in
  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  // Car management methods
  Future<void> registerCar(String userId, Car car) async {
    try {
      final response = await supabase.from('cars').insert({
        'user_id': userId,
        'brand': car.brand,
        'model': car.model,
        'engine_type': car.engineType,
        'mileage': car.mileage,
        'region': car.region,
        'make_year': car.makeYear,
        'engine_capacity': car.engineCapacity,
        'license_start_date': car.licenseStartDate,
        'license_validity_months': car.licenseValidityMonths,
        'insurance_start_date': car.insuranceStartDate,
        'insurance_validity_months': car.insuranceValidityMonths,
        'last_oil_change_date': car.lastOilChangeDate,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isEmpty) {
        throw Exception('Failed to register car: No response from server');
      }
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to register car: $e');
    }
  }

  Future<List<Car>> getUserCars(String userId) async {
    try {
      logger.i('Fetching cars for user: $userId');

      final response = await supabase
          .from('cars')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      logger.d('Raw response from Supabase: $response');

      final cars = (response as List)
          .map((car) => Car.fromJson({...car, 'id': car['id']}))
          .toList();

      logger.i('Found ${cars.length} cars for user $userId');
      return cars;
    } on PostgrestException catch (e) {
      logger.e('Database error while fetching cars: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      logger.e('Unexpected error while fetching cars: $e');
      throw Exception('Failed to fetch cars: $e');
    }
  }

  Future<void> updateCar(String carId, Car car) async {
    try {
      final response = await supabase
          .from('cars')
          .update({
            'brand': car.brand,
            'model': car.model,
            'engine_type': car.engineType,
            'mileage': car.mileage,
            'region': car.region,
            'make_year': car.makeYear,
            'engine_capacity': car.engineCapacity,
            'license_start_date': car.licenseStartDate,
            'license_validity_months': car.licenseValidityMonths,
            'insurance_start_date': car.insuranceStartDate,
            'insurance_validity_months': car.insuranceValidityMonths,
            'last_oil_change_date': car.lastOilChangeDate,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', carId)
          .select();

      if (response.isEmpty) {
        throw Exception('Car not found or update failed');
      }
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update car: $e');
    }
  }

  Future<void> deleteCar(String carId) async {
    try {
      final response =
          await supabase.from('cars').delete().eq('id', carId).select();

      if (response.isEmpty) {
        throw Exception('Car not found or delete failed');
      }
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete car: $e');
    }
  }

  Future<Car?> getCarById(String carId) async {
    try {
      final response =
          await supabase.from('cars').select().eq('id', carId).single();

      return response != null ? Car.fromJson({...response, 'id': carId}) : null;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch car: $e');
    }
  }

  // Document management methods
  Future<Document> uploadDocument(
    String userId,
    String category,
    String description,
    String fileName,
    Uint8List fileBytes,
    String fileType,
  ) async {
    try {
      logger.i('Starting document upload for user: $userId');
      logger.i('File details - Name: $fileName, Type: $fileType, Size: ${fileBytes.length} bytes');

      // 1. Upload file to Supabase Storage
      final String filePath = 'documents/$userId/$fileName';
      logger.i('Uploading to path: $filePath');

      final storageResponse = await supabase.storage
          .from('documents')
          .uploadBinary(filePath, fileBytes);

      if (storageResponse.isEmpty) {
        logger.e('Storage response was empty');
        throw Exception('Failed to upload file to storage');
      }
      logger.i('File uploaded successfully to storage');

      // 2. Get the public URL for the uploaded file
      final String fileUrl =
          supabase.storage.from('documents').getPublicUrl(filePath);
      logger.i('Generated public URL: $fileUrl');

      // 3. Create document record in the database
      logger.i('Creating database record for document');
      final response = await supabase
          .from('documents')
          .insert({
            'user_id': userId,
            'category': category,
            'description': description,
            'file_url': fileUrl,
            'file_name': fileName,
            'file_type': fileType,
            'file_size': fileBytes.length,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      logger.i('Document record created successfully');
      return Document.fromJson(response);
    } on StorageException catch (e) {
      logger.e('Storage error during document upload', error: e);
      throw Exception('Storage error: ${e.message}');
    } on PostgrestException catch (e) {
      logger.e('Database error during document upload', error: e);
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      logger.e('Unexpected error during document upload', error: e);
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<List<Document>> getUserDocuments(String userId) async {
    try {
      final response = await supabase
          .from('documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((doc) => Document.fromJson(doc)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  Future<Document?> getDocumentById(String documentId) async {
    try {
      final response = await supabase
          .from('documents')
          .select()
          .eq('id', documentId)
          .single();

      return response != null ? Document.fromJson(response) : null;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch document: $e');
    }
  }

  Future<void> deleteDocument(String userId, String documentId) async {
    try {
      // 1. Get document details
      final document = await getDocumentById(documentId);
      if (document == null) {
        throw Exception('Document not found');
      }

      // 2. Delete file from storage
      final String filePath = 'documents/$userId/${document.fileName}';
      await supabase.storage.from('documents').remove([filePath]);

      // 3. Delete document record from database
      final response = await supabase
          .from('documents')
          .delete()
          .eq('id', documentId)
          .select();

      if (response.isEmpty) {
        throw Exception('Document not found or delete failed');
      }
    } on StorageException catch (e) {
      throw Exception('Storage error: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<void> updateDocument(
    String documentId, {
    String? category,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (updates.isEmpty) {
        return; // Nothing to update
      }

      final response = await supabase
          .from('documents')
          .update(updates)
          .eq('id', documentId)
          .select();

      if (response.isEmpty) {
        throw Exception('Document not found or update failed');
      }
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  // Parking management methods
  Future<Parking> saveParking(
    String userId,
    double latitude,
    double longitude, {
    Uint8List? photoBytes,
    String? photoName,
    String? description,
  }) async {
    try {
      String? photoUrl;

      // Upload photo if provided
      if (photoBytes != null && photoName != null) {
        final String filePath = 'parking/$userId/$photoName';
        final storageResponse = await supabase.storage
            .from('parking')
            .uploadBinary(filePath, photoBytes);

        if (storageResponse.isEmpty) {
          throw Exception('Failed to upload photo to storage');
        }

        photoUrl = supabase.storage.from('parking').getPublicUrl(filePath);
      }

      // Create parking record in database
      final response = await supabase
          .from('parking')
          .insert({
            'user_id': userId,
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now().toIso8601String(),
            if (photoUrl != null) 'photo_url': photoUrl,
            if (photoName != null) 'photo_name': photoName,
            if (description != null) 'description': description,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Parking.fromJson(response);
    } on StorageException catch (e) {
      throw Exception('Storage error: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to save parking location: $e');
    }
  }

  Future<List<Parking>> getUserParkingLocations(String userId) async {
    try {
      final response = await supabase
          .from('parking')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((parking) => Parking.fromJson(parking))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch parking locations: $e');
    }
  }

  Future<Parking?> getParkingById(String parkingId) async {
    try {
      final response =
          await supabase.from('parking').select().eq('id', parkingId).single();

      return response != null ? Parking.fromJson(response) : null;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch parking location: $e');
    }
  }

  Future<void> deleteParking(String userId, String parkingId) async {
    try {
      // Get parking details to check if there's a photo to delete
      final parking = await getParkingById(parkingId);
      if (parking == null) {
        throw Exception('Parking location not found');
      }

      // Delete photo if exists
      if (parking.photoName != null) {
        final String filePath = 'parking/$userId/${parking.photoName}';
        await supabase.storage.from('parking').remove([filePath]);
      }

      // Delete parking record
      final response =
          await supabase.from('parking').delete().eq('id', parkingId).select();

      if (response.isEmpty) {
        throw Exception('Parking location not found or delete failed');
      }
    } on StorageException catch (e) {
      throw Exception('Storage error: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete parking location: $e');
    }
  }

  Future<void> updateParking(
    String parkingId, {
    String? description,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        if (description != null) 'description': description,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (updates.isEmpty) {
        return; // Nothing to update
      }

      final response = await supabase
          .from('parking')
          .update(updates)
          .eq('id', parkingId)
          .select();

      if (response.isEmpty) {
        throw Exception('Parking location not found or update failed');
      }
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update parking location: $e');
    }
  }

  // Event management methods
  Future<Event> createEvent(Event event) async {
    try {
      final response = await supabase
          .from('events')
          .insert({
            'user_id': event.userId,
            'title': event.title,
            'description': event.description,
            'date': event.date.toIso8601String(),
            'event_type': event.eventType,
            if (event.fuelNeeded != null) 'fuel_needed': event.fuelNeeded,
            if (event.location != null) 'location': event.location,
            'is_completed': event.isCompleted,
            if (event.reminderTime != null) 'reminder_time': event.reminderTime,
            if (event.notes != null) 'notes': event.notes,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Event.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  Future<List<Event>> getUserEvents(String userId, {DateTime? fromDate}) async {
    try {
      var query = supabase.from('events').select().eq('user_id', userId);

      if (fromDate != null) {
        query = query.gte('date', fromDate.toIso8601String());
      }

      final response = await query.order('date');

      return (response as List).map((event) => Event.fromJson(event)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<List<Event>> getUpcomingEvents(String userId) async {
    try {
      final now = DateTime.now();
      final response = await supabase
          .from('events')
          .select()
          .eq('user_id', userId)
          .eq('is_completed', false)
          .gte('date', now.toIso8601String())
          .order('date')
          .limit(10);

      return (response as List).map((event) => Event.fromJson(event)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch upcoming events: $e');
    }
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      final response =
          await supabase.from('events').select().eq('id', eventId).single();

      return response != null ? Event.fromJson(response) : null;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  Future<void> updateEvent(
    String eventId, {
    String? title,
    String? description,
    DateTime? date,
    String? eventType,
    double? fuelNeeded,
    String? location,
    bool? isCompleted,
    String? reminderTime,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (date != null) 'date': date.toIso8601String(),
        if (eventType != null) 'event_type': eventType,
        if (fuelNeeded != null) 'fuel_needed': fuelNeeded,
        if (location != null) 'location': location,
        if (isCompleted != null) 'is_completed': isCompleted,
        if (reminderTime != null) 'reminder_time': reminderTime,
        if (notes != null) 'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (updates.isEmpty) {
        return; // Nothing to update
      }

      final response = await supabase
          .from('events')
          .update(updates)
          .eq('id', eventId)
          .select();

      if (response.isEmpty) {
        throw Exception('Event not found or update failed');
      }
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final response =
          await supabase.from('events').delete().eq('id', eventId).select();

      if (response.isEmpty) {
        throw Exception('Event not found or delete failed');
      }
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  Future<List<Event>> searchEvents(String userId, String searchTerm) async {
    try {
      final response = await supabase
          .from('events')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$searchTerm%,description.ilike.%$searchTerm%')
          .order('date');

      return (response as List).map((event) => Event.fromJson(event)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }

  // User profile methods
  Future<app_models.User> getUserProfile(String userId) async {
    logger.i('Fetching user profile for userId: $userId');
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      logger.d('Raw response from Supabase: $response');

      if (response == null) {
        logger.e('No user profile found for userId: $userId');
        throw Exception('User profile not found');
      }

      final user = app_models.User.fromJson({...response, 'id': userId});
      logger.i('Successfully fetched profile for user: ${user.name}');
      return user;
    } on PostgrestException catch (e) {
      logger.e('Database error while fetching user profile: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      logger.e('Unexpected error while fetching user profile: $e');
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? location,
    String? licenseStartDate,
    int? licenseValidityMonths,
  }) async {
    logger.i('Updating profile for userId: $userId');
    try {
      final Map<String, dynamic> updates = {
        if (name != null) 'name': name,
        if (location != null) 'location': location,
        if (licenseStartDate != null) 'license_start_date': licenseStartDate,
        if (licenseValidityMonths != null)
          'license_validity_months': licenseValidityMonths,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (updates.isEmpty) {
        logger.w('No updates provided for user profile');
        return; // Nothing to update
      }

      logger.d('Updating user profile with data: $updates');

      final response = await supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select();

      if (response.isEmpty) {
        logger.e('User not found or update failed for userId: $userId');
        throw Exception('User not found or update failed');
      }

      logger.i('Successfully updated profile for userId: $userId');
    } on PostgrestException catch (e) {
      logger.e('Database error while updating user profile: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      logger.e('Unexpected error while updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<Parking?> getLatestParking(String userId) async {
    try {
      final response = await supabase
          .from('parking')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? Parking.fromJson(response) : null;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch latest parking location: $e');
    }
  }

  Future<void> clearParking(String userId) async {
    try {
      // Get the latest parking to delete any associated photo
      final latestParking = await getLatestParking(userId);
      if (latestParking?.photoName != null) {
        final String filePath = 'parking/$userId/${latestParking!.photoName}';
        await supabase.storage.from('parking').remove([filePath]);
      }

      // Delete all parking records for the user
      final response = await supabase
          .from('parking')
          .delete()
          .eq('user_id', userId)
          .select();

      if (response.isEmpty) {
        throw Exception('No parking locations found or delete failed');
      }
    } on StorageException catch (e) {
      throw Exception('Storage error: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to clear parking locations: $e');
    }
  }
}
