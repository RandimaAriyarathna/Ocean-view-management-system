package com.oceanview.service;

import com.oceanview.dao.ReservationDao;
import com.oceanview.dao.GuestDao;
import com.oceanview.dao.RoomDao;
import com.oceanview.model.Reservation;
import com.oceanview.model.Guest;
import com.oceanview.model.Room;
import com.oceanview.dao.DBConnection;

import java.sql.Connection;
import java.sql.Date;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public class ReservationService {

    private ReservationDao reservationDao;
    private GuestDao guestDao;
    private RoomDao roomDao;

    public ReservationService() {
        this.reservationDao = new ReservationDao();
        this.guestDao = new GuestDao();
        this.roomDao = new RoomDao();
    }

    // ============================================================
    // TEST DATABASE CONNECTION
    // ============================================================
    public boolean testConnection() {
        System.out.println("🔍 Testing database connection...");
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null && !conn.isClosed()) {
                System.out.println("✅ Database connection successful");
                return true;
            }
        } catch (SQLException e) {
            System.err.println("❌ Database connection failed: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
        return false;
    }

    // ============================================================
    // CREATE RESERVATION
    // ============================================================
    public ServiceResult<Reservation> createReservation(
            Reservation reservation,
            Guest guest,
            String roomNumber) {

        try {
            System.out.println("\n=== CREATE RESERVATION ===");

            // 1️⃣ VALIDATION
            if (guest == null || guest.getName() == null || guest.getName().trim().isEmpty()) {
                return ServiceResult.error("Guest name is required");
            }

            if (guest.getContactNumber() == null || guest.getContactNumber().trim().isEmpty()) {
                return ServiceResult.error("Contact number is required");
            }

            if (reservation == null || reservation.getRoomType() == null 
                    || reservation.getRoomType().trim().isEmpty()) {
                return ServiceResult.error("Room type is required");
            }

            if (!validateDates(reservation.getCheckIn(), reservation.getCheckOut())) {
                return ServiceResult.error("Invalid check-in or check-out date");
            }

            // =====================================================
            // 2️⃣ FIND OR CREATE GUEST
            // =====================================================
            int guestId;

            if (guest.getGuestId() > 0) {
                // Existing guest → update
                boolean updated = guestDao.updateGuest(guest);
                if (!updated) {
                    return ServiceResult.error("Failed to update guest information");
                }
                guestId = guest.getGuestId();
                System.out.println("✅ Existing guest updated. ID: " + guestId);

            } else {
                // New guest → insert
                guestId = guestDao.addGuest(guest);
                if (guestId <= 0) {
                    return ServiceResult.error("Failed to create guest");
                }
                System.out.println("✅ New guest created. ID: " + guestId);
            }

            // =====================================================
            // 3️⃣ CHECK DUPLICATE RESERVATIONS FOR THIS GUEST
            // =====================================================
            List<Reservation> guestReservations =
                    reservationDao.getFutureReservationsByGuestId(guestId);

            for (Reservation r : guestReservations) {
                if (datesOverlap(
                        r.getCheckIn(),
                        r.getCheckOut(),
                        reservation.getCheckIn(),
                        reservation.getCheckOut())) {

                    return ServiceResult.error(
                            "Guest already has a reservation from "
                                    + r.getCheckIn() + " to " + r.getCheckOut());
                }
            }

            // =====================================================
            // 4️⃣ ROOM ASSIGNMENT AND AVAILABILITY CHECK
            // =====================================================
            String assignedRoom;
            Room selectedRoom = null;

            // CASE 1: User selected a specific room
            if (roomNumber != null && !roomNumber.trim().isEmpty()
                    && !roomNumber.equalsIgnoreCase("AUTO")) {

                System.out.println("🔍 Checking specific room: " + roomNumber);
                
                // Check if room exists
                selectedRoom = roomDao.getRoomByNumber(roomNumber.trim());
                if (selectedRoom == null) {
                    return ServiceResult.error("Room " + roomNumber + " does not exist");
                }

                // Check if room type matches
                if (!selectedRoom.getRoomType().equals(reservation.getRoomType())) {
                    return ServiceResult.error("Room type mismatch: Selected room is " + 
                                               selectedRoom.getRoomType() + " but reservation is for " + 
                                               reservation.getRoomType());
                }

                // CRITICAL: Check if room is available for the selected dates
                if (!isRoomAvailableForDates(
                        roomNumber.trim(),
                        reservation.getCheckIn(),
                        reservation.getCheckOut())) {

                    // Try to find an alternative room as suggestion
                    Room alternative = roomDao.getBestAvailableRoom(
                            reservation.getRoomType(),
                            Date.valueOf(reservation.getCheckIn()),
                            Date.valueOf(reservation.getCheckOut())
                    );
                    
                    String errorMsg = "Room " + roomNumber + " is not available for the selected dates.";
                    if (alternative != null) {
                        errorMsg += " However, room " + alternative.getRoomNumber() + " is available.";
                    }
                    return ServiceResult.error(errorMsg);
                }

                assignedRoom = roomNumber.trim();
                System.out.println("✅ Room " + assignedRoom + " is available and will be assigned");

            // CASE 2: Auto-assign best available room
            } else {
                System.out.println("🔍 Auto-assigning best available room for type: " + reservation.getRoomType());
                
                Room availableRoom = roomDao.getBestAvailableRoom(
                        reservation.getRoomType(),
                        Date.valueOf(reservation.getCheckIn()),
                        Date.valueOf(reservation.getCheckOut())
                );

                if (availableRoom == null) {
                    return ServiceResult.error(
                            "No " + reservation.getRoomType()
                                    + " rooms available for selected dates");
                }

                assignedRoom = availableRoom.getRoomNumber();
                System.out.println("✅ Auto-assigned room: " + assignedRoom);
            }

            // =====================================================
            // 5️⃣ GENERATE RESERVATION NUMBER
            // =====================================================
            String reservationNumber = generateReservationNumber();

            reservation.setReservationNumber(reservationNumber);
            reservation.setGuestId(guestId);
            reservation.setRoomNumber(assignedRoom);

            // =====================================================
            // 6️⃣ FINAL AVAILABILITY CHECK (to prevent race conditions)
            // =====================================================
            // Double-check one more time right before saving
            if (!isRoomAvailableForDates(
                    assignedRoom,
                    reservation.getCheckIn(),
                    reservation.getCheckOut())) {
                
                // Try auto-assign as fallback
                Room fallbackRoom = roomDao.getBestAvailableRoom(
                        reservation.getRoomType(),
                        Date.valueOf(reservation.getCheckIn()),
                        Date.valueOf(reservation.getCheckOut())
                );
                
                if (fallbackRoom != null) {
                    assignedRoom = fallbackRoom.getRoomNumber();
                    reservation.setRoomNumber(assignedRoom);
                    System.out.println("✅ Fallback room assigned: " + assignedRoom);
                } else {
                    return ServiceResult.error(
                            "Room " + assignedRoom + " was just booked by someone else. " +
                            "No alternative rooms available. Please try different dates.");
                }
            }

            // =====================================================
            // 7️⃣ SAVE RESERVATION
            // =====================================================
            boolean saved = reservationDao.addReservation(reservation, guestId);

            if (!saved) {
                return ServiceResult.error("Failed to save reservation");
            }

            // Update room status based on check-in date
            LocalDate today = LocalDate.now();
            String roomStatus;
            
            if (reservation.getCheckIn().isAfter(today)) {
                roomStatus = "BOOKED"; // Future reservation
            } else if (!reservation.getCheckIn().isAfter(today) && !reservation.getCheckOut().isBefore(today)) {
                roomStatus = "OCCUPIED"; // Current stay
            } else {
                roomStatus = "BOOKED";
            }
            
            roomDao.updateRoomStatus(assignedRoom, roomStatus);
            System.out.println("✅ Room " + assignedRoom + " status set to: " + roomStatus);

            System.out.println("✅ Reservation created successfully");

            return ServiceResult.success(reservation,
                    "Reservation " + reservationNumber + " created successfully!");

        } catch (Exception e) {
            e.printStackTrace();
            return ServiceResult.error("System error: " + e.getMessage());
        }
    }

    // ============================================================
    // CHECK ROOM AVAILABILITY FOR DATES (NEW METHOD)
    // ============================================================
    private boolean isRoomAvailableForDates(
            String roomNumber,
            LocalDate checkIn,
            LocalDate checkOut) {

        System.out.println("\n🔍 CHECKING ROOM AVAILABILITY FOR DATES");
        System.out.println("Room: " + roomNumber);
        System.out.println("Dates: " + checkIn + " to " + checkOut);

        List<Reservation> allReservations = reservationDao.getAllReservations();
        System.out.println("Total reservations in system: " + allReservations.size());

        for (Reservation r : allReservations) {
            // Skip reservations without room numbers
            if (r.getRoomNumber() == null || r.getRoomNumber().isEmpty()) {
                continue;
            }

            if (roomNumber.equals(r.getRoomNumber())) {
                System.out.println("📅 Found reservation for room " + roomNumber + 
                                 ": " + r.getReservationNumber() + 
                                 " (" + r.getCheckIn() + " to " + r.getCheckOut() + ")");
                
                if (datesOverlap(r.getCheckIn(), r.getCheckOut(), checkIn, checkOut)) {
                    System.out.println("❌ OVERLAP DETECTED! Room not available");
                    return false;
                } else {
                    System.out.println("✅ No overlap with this reservation");
                }
            }
        }
        
        System.out.println("✅ Room " + roomNumber + " is AVAILABLE for selected dates");
        return true;
    }

    // ============================================================
    // GET RESERVATION BY NUMBER
    // ============================================================
    public ServiceResult<Reservation> getReservationByNumber(String reservationNumber) {

        try {
            System.out.println("🔍 Getting reservation by number: " + reservationNumber);
            
            if (reservationNumber == null || reservationNumber.trim().isEmpty()) {
                return ServiceResult.error("Reservation number is required");
            }

            Reservation reservation = reservationDao.getReservationByNumber(reservationNumber);

            if (reservation == null) {
                System.out.println("❌ Reservation not found: " + reservationNumber);
                return ServiceResult.error("Reservation not found");
            }

            System.out.println("✅ Reservation loaded: " + reservation.getReservationNumber());
            System.out.println("   Guest: " + reservation.getGuestName());
            System.out.println("   Dates: " + reservation.getCheckIn() + " to " + reservation.getCheckOut());
            
            return ServiceResult.success(reservation, "Reservation loaded successfully");

        } catch (Exception e) {
            System.err.println("❌ Error in getReservationByNumber: " + e.getMessage());
            e.printStackTrace();
            return ServiceResult.error("Failed to load reservation: " + e.getMessage());
        }
    }

    // ============================================================
    // GET ALL RESERVATIONS
    // ============================================================
    public ServiceResult<List<Reservation>> getAllReservations() {

        try {
            System.out.println("🔍 Getting all reservations...");
            
            List<Reservation> reservations = reservationDao.getAllReservations();

            System.out.println("✅ Loaded " + reservations.size() + " reservations");
            
            return ServiceResult.success(
                    reservations,
                    "Loaded " + reservations.size() + " reservations");

        } catch (Exception e) {
            System.err.println("❌ Error in getAllReservations: " + e.getMessage());
            e.printStackTrace();
            return ServiceResult.error("Failed to load reservations: " + e.getMessage());
        }
    }

    // ============================================================
    // SEARCH RESERVATIONS
    // ============================================================
    public ServiceResult<List<Reservation>> searchReservations(String term) {

        try {
            System.out.println("🔍 Searching reservations for: " + term);
            
            if (term == null || term.trim().isEmpty()) {
                return ServiceResult.error("Search term is required");
            }

            List<Reservation> list = reservationDao.searchReservations(term);

            System.out.println("✅ Found " + list.size() + " results for: " + term);
            
            return ServiceResult.success(
                    list,
                    "Found " + list.size() + " results");

        } catch (Exception e) {
            System.err.println("❌ Error in searchReservations: " + e.getMessage());
            e.printStackTrace();
            return ServiceResult.error("Search failed: " + e.getMessage());
        }
    }

    // ============================================================
    // DELETE RESERVATION
    // ============================================================
    public ServiceResult<Boolean> deleteReservation(String reservationNumber) {

        try {
            System.out.println("🔍 Deleting reservation: " + reservationNumber);
            
            if (reservationNumber == null || reservationNumber.trim().isEmpty()) {
                return ServiceResult.error("Reservation number is required");
            }

            Reservation existing = reservationDao.getReservationByNumber(reservationNumber);

            if (existing == null) {
                System.out.println("❌ Reservation not found: " + reservationNumber);
                return ServiceResult.error("Reservation not found");
            }

            // Free the room if assigned
            if (existing.getRoomNumber() != null && !existing.getRoomNumber().isEmpty()) {
                roomDao.updateRoomStatus(existing.getRoomNumber(), "AVAILABLE");
                System.out.println("✅ Room " + existing.getRoomNumber() + " freed");
            }

            boolean deleted = reservationDao.deleteReservation(reservationNumber);

            if (!deleted) {
                return ServiceResult.error("Failed to delete reservation");
            }

            System.out.println("✅ Reservation " + reservationNumber + " deleted successfully");
            
            return ServiceResult.success(true, "Reservation " + reservationNumber + " deleted successfully");

        } catch (Exception e) {
            System.err.println("❌ Error in deleteReservation: " + e.getMessage());
            e.printStackTrace();
            return ServiceResult.error("System error: " + e.getMessage());
        }
    }

    // ============================================================
    // UPDATE RESERVATION
    // ============================================================
    public ServiceResult<Reservation> editReservation(Reservation reservation, Guest guest) {
        try {
            System.out.println("\n=== EDIT RESERVATION ===");
            System.out.println("Editing reservation: " + reservation.getReservationNumber());
            System.out.println("Guest ID: " + guest.getGuestId());
            System.out.println("Guest Name: " + guest.getName());

            if (reservation.getReservationNumber() == null || reservation.getReservationNumber().trim().isEmpty()) {
                return ServiceResult.error("Reservation number is required");
            }

            Reservation existing = reservationDao.getReservationByNumber(reservation.getReservationNumber());
            if (existing == null) {
                return ServiceResult.error("Reservation not found");
            }
            
            System.out.println("Existing reservation loaded:");
            System.out.println("  Existing Room: " + existing.getRoomNumber());
            System.out.println("  New Room: " + reservation.getRoomNumber());
            System.out.println("  Existing Dates: " + existing.getCheckIn() + " to " + existing.getCheckOut());
            System.out.println("  New Dates: " + reservation.getCheckIn() + " to " + reservation.getCheckOut());

            if (!validateDates(reservation.getCheckIn(), reservation.getCheckOut())) {
                return ServiceResult.error("Invalid check-in or check-out date");
            }

            boolean guestUpdated = guestDao.updateGuest(guest);
            if (!guestUpdated) {
                return ServiceResult.error("Failed to update guest information");
            }
            System.out.println("✅ Guest updated with ID: " + guest.getGuestId());

            String oldRoom = existing.getRoomNumber();
            String newRoom = reservation.getRoomNumber();
            
            boolean datesChanged = !existing.getCheckIn().equals(reservation.getCheckIn()) ||
                                   !existing.getCheckOut().equals(reservation.getCheckOut());
            boolean roomChanged = (newRoom != null && !newRoom.equals(oldRoom));

            if (newRoom != null && newRoom.equalsIgnoreCase("AUTO")) {
                Room availableRoom = roomDao.getBestAvailableRoom(
                        reservation.getRoomType(),
                        Date.valueOf(reservation.getCheckIn()),
                        Date.valueOf(reservation.getCheckOut())
                );
                
                if (availableRoom == null) {
                    return ServiceResult.error(
                            "No " + reservation.getRoomType() 
                            + " rooms available for selected dates");
                }
                
                reservation.setRoomNumber(availableRoom.getRoomNumber());
                newRoom = availableRoom.getRoomNumber();
                roomChanged = true;
                System.out.println("✅ Auto-assigned room: " + newRoom);
            }

            if ((roomChanged || datesChanged) && newRoom != null && !newRoom.isEmpty()) {
                if (!newRoom.equals(oldRoom) || datesChanged) {
                    Room room = roomDao.getRoomByNumber(newRoom);
                    if (room == null) {
                        return ServiceResult.error("Room " + newRoom + " does not exist");
                    }
                    
                    if (!room.getRoomType().equals(reservation.getRoomType())) {
                        return ServiceResult.error("Room type mismatch: Selected room is " + 
                                                   room.getRoomType() + " but reservation is for " + 
                                                   reservation.getRoomType());
                    }

                    if (!isRoomAvailableForEdit(
                            newRoom, 
                            reservation.getCheckIn(), 
                            reservation.getCheckOut(), 
                            existing.getReservationNumber())) {
                        
                        return ServiceResult.error("Room " + newRoom + " is not available for the selected dates");
                    }
                }
            }

            reservation.setGuestId(existing.getGuestId());
            
            boolean updated = reservationDao.updateReservation(reservation);
            if (!updated) {
                return ServiceResult.error("Failed to update reservation");
            }
            System.out.println("✅ Reservation updated in database");

            if (roomChanged) {
                if (oldRoom != null && !oldRoom.isEmpty() && !oldRoom.equals(newRoom)) {
                    roomDao.updateRoomStatus(oldRoom, "AVAILABLE");
                    System.out.println("✅ Old room " + oldRoom + " set to AVAILABLE");
                }
                if (newRoom != null && !newRoom.isEmpty()) {
                    roomDao.updateRoomStatus(newRoom, "OCCUPIED");
                    System.out.println("✅ New room " + newRoom + " set to OCCUPIED");
                }
            }

            Reservation updatedReservation = reservationDao.getReservationByNumber(reservation.getReservationNumber());
            
            if (updatedReservation == null) {
                return ServiceResult.error("Failed to reload reservation after update");
            }

            System.out.println("✅ Reservation updated successfully");
            System.out.println("   Updated guest name: " + updatedReservation.getGuestName());
            System.out.println("   Room: " + updatedReservation.getRoomNumber());
            System.out.println("   Dates: " + updatedReservation.getCheckIn() + " to " + updatedReservation.getCheckOut());
            
            return ServiceResult.success(updatedReservation, "Reservation updated successfully");

        } catch (Exception e) {
            e.printStackTrace();
            return ServiceResult.error("System error: " + e.getMessage());
        }
    }

    // ============================================================
    // CHECK ROOM AVAILABILITY (EXCLUDING CURRENT GUEST)
    // ============================================================
    private boolean isRoomAvailable(
            String roomNumber,
            LocalDate checkIn,
            LocalDate checkOut,
            int currentGuestId) {

        List<Reservation> allReservations = reservationDao.getAllReservations();

        for (Reservation r : allReservations) {
            if (r.getGuestId() == currentGuestId) {
                continue;
            }

            if (roomNumber.equals(r.getRoomNumber())) {
                if (datesOverlap(
                        r.getCheckIn(),
                        r.getCheckOut(),
                        checkIn,
                        checkOut)) {
                    
                    System.out.println("Room " + roomNumber + " is booked by guest " + 
                                     r.getGuestId() + " from " + r.getCheckIn() + " to " + r.getCheckOut());
                    return false;
                }
            }
        }
        return true;
    }

    // ============================================================
    // CHECK ROOM AVAILABILITY FOR EDIT (EXCLUDING CURRENT RESERVATION)
    // ============================================================
    private boolean isRoomAvailableForEdit(
            String roomNumber,
            LocalDate checkIn,
            LocalDate checkOut,
            String currentReservationNumber) {

        List<Reservation> allReservations = reservationDao.getAllReservations();

        for (Reservation r : allReservations) {
            if (r.getReservationNumber().equals(currentReservationNumber)) {
                continue;
            }

            if (roomNumber.equals(r.getRoomNumber())) {
                if (datesOverlap(
                        r.getCheckIn(),
                        r.getCheckOut(),
                        checkIn,
                        checkOut)) {
                    
                    System.out.println("Room " + roomNumber + " is booked by reservation " + 
                                     r.getReservationNumber() + " from " + r.getCheckIn() + " to " + r.getCheckOut());
                    return false;
                }
            }
        }
        return true;
    }

    // ============================================================
    // DATE OVERLAP (CORRECT HOTEL LOGIC)
    // ============================================================
    private boolean datesOverlap(
            LocalDate existingStart,
            LocalDate existingEnd,
            LocalDate newStart,
            LocalDate newEnd) {

        if (existingStart == null || existingEnd == null
                || newStart == null || newEnd == null) {
            return false;
        }

        // A reservation overlaps if:
        // New check-in is BEFORE existing check-out AND
        // New check-out is AFTER existing check-in
        
        boolean overlap = newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);
        
        System.out.println("   Checking overlap: [" + existingStart + " to " + existingEnd + 
                          "] vs [" + newStart + " to " + newEnd + "] = " + overlap);
        
        return overlap;
    }

    // ============================================================
    // DATE VALIDATION
    // ============================================================
    private boolean validateDates(LocalDate checkIn, LocalDate checkOut) {

        if (checkIn == null || checkOut == null) {
            return false;
        }

        LocalDate today = LocalDate.now();

        if (checkIn.isBefore(today)) {
            System.out.println("Check-in date " + checkIn + " is before today " + today);
            return false;
        }

        if (checkOut.isBefore(checkIn) || checkOut.isEqual(checkIn)) {
            System.out.println("Check-out " + checkOut + " must be after check-in " + checkIn);
            return false;
        }

        return true;
    }

    // ============================================================
    // GENERATE RESERVATION NUMBER
    // ============================================================
    private String generateReservationNumber() {
        String prefix = "RES";
        String timestamp = String.valueOf(System.currentTimeMillis()).substring(7);
        String random = UUID.randomUUID().toString()
                .substring(0, 4)
                .toUpperCase();
        return prefix + "-" + timestamp + random;
    }
}