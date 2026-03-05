package com.oceanview.dao;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import com.oceanview.model.Reservation;
import com.oceanview.model.Guest;

public class ReservationDao {
    
    // ============ ADD RESERVATION WITH GUEST ID ============
    public boolean addReservation(Reservation reservation, int guestId) {
        String sql = "INSERT INTO reservations (reservation_number, guest_id, room_type, " +
                     "check_in, check_out, room_number) VALUES (?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            System.out.println("\n=== ADDING RESERVATION ===");
            System.out.println("Reservation Number: " + reservation.getReservationNumber());
            System.out.println("Guest ID: " + guestId);
            System.out.println("Room Type: " + reservation.getRoomType());
            System.out.println("Check-in: " + reservation.getCheckIn());
            System.out.println("Check-out: " + reservation.getCheckOut());
            System.out.println("Room Number: " + reservation.getRoomNumber());
            
            ps.setString(1, reservation.getReservationNumber());
            ps.setInt(2, guestId);
            ps.setString(3, reservation.getRoomType());
            ps.setDate(4, Date.valueOf(reservation.getCheckIn()));
            ps.setDate(5, Date.valueOf(reservation.getCheckOut()));
            
            if (reservation.getRoomNumber() != null && !reservation.getRoomNumber().trim().isEmpty()) {
                ps.setString(6, reservation.getRoomNumber().trim());
            } else {
                ps.setNull(6, Types.VARCHAR);
            }
            
            int rows = ps.executeUpdate();
            boolean success = rows > 0;
            
            System.out.println("Insert result: " + (success ? "✅ SUCCESS" : "❌ FAILED"));
            return success;
            
        } catch (SQLException e) {
            System.err.println("❌ SQL Error in addReservation: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
 // ============ CHECK IF ROOM IS AVAILABLE FOR DATES ============
    public boolean isRoomAvailable(String roomNumber, LocalDate checkIn, LocalDate checkOut) {

        String sql = "SELECT COUNT(*) FROM reservations " +
                     "WHERE room_number = ? " +
                     "AND check_in < ? " +
                     "AND check_out > ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, roomNumber);
            ps.setDate(2, Date.valueOf(checkOut));
            ps.setDate(3, Date.valueOf(checkIn));

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                int count = rs.getInt(1);

                System.out.println("🔍 Room " + roomNumber + " overlapping reservations: " + count);

                return count == 0; // If 0 -> room is available
            }

        } catch (SQLException e) {
            System.err.println("Error checking room availability: " + e.getMessage());
            e.printStackTrace();
        }

        return false;
    }
    
 // ============ GET AVAILABLE ROOMS FOR DATES ============
    public List<String> getAvailableRooms(String roomType, LocalDate checkIn, LocalDate checkOut) {

        List<String> availableRooms = new ArrayList<>();

        String roomsSql = "SELECT room_number FROM rooms WHERE room_type = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(roomsSql)) {

            ps.setString(1, roomType);

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {

                String roomNumber = rs.getString("room_number");

                System.out.println("Checking room: " + roomNumber);

                if (isRoomAvailable(roomNumber, checkIn, checkOut)) {

                    availableRooms.add(roomNumber);

                    System.out.println("✅ Room available: " + roomNumber);

                } else {

                    System.out.println("❌ Room not available: " + roomNumber);

                }
            }

            System.out.println("📊 Total available rooms found: " + availableRooms.size());

        } catch (SQLException e) {

            System.err.println("Error getting available rooms: " + e.getMessage());
            e.printStackTrace();
        }

        return availableRooms;
    }
    
    // ============ GET BEST AVAILABLE ROOM ============
    public String getBestAvailableRoom(String roomType, LocalDate checkIn, LocalDate checkOut) {
        List<String> availableRooms = getAvailableRooms(roomType, checkIn, checkOut);
        
        if (availableRooms.isEmpty()) {
            return null;
        }
        
        // Return the first available room (you can add sorting logic here)
        return availableRooms.get(0);
    }
    
    // ============ GET RESERVATIONS BY GUEST ID (ALL) - REMOVED STATUS ============
    public List<Reservation> getReservationsByGuestId(int guestId) {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.reservation_number, r.room_type, r.room_number, r.check_in, r.check_out, " +
                     "g.name as guest_name, g.address, g.contact_number, g.guest_id " +
                     "FROM reservations r " +
                     "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                     "WHERE r.guest_id = ? " +
                     "ORDER BY r.check_in DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, guestId);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Reservation reservation = extractReservationFromResultSet(rs);
                if (reservation != null) {
                    reservations.add(reservation);
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting reservations by guest ID: " + e.getMessage());
            e.printStackTrace();
        }
        return reservations;
    }
    
    // ============ GET FUTURE RESERVATIONS BY GUEST ID - REMOVED STATUS ============
    public List<Reservation> getFutureReservationsByGuestId(int guestId) {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.reservation_number, r.room_type, r.room_number, r.check_in, r.check_out, " +
                     "g.name as guest_name, g.address, g.contact_number, g.guest_id " +
                     "FROM reservations r " +
                     "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                     "WHERE r.guest_id = ? " +
                     "AND r.check_out >= CURDATE() " + // Only future and current reservations
                     "ORDER BY r.check_in ASC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, guestId);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Reservation reservation = extractReservationFromResultSet(rs);
                if (reservation != null) {
                    reservations.add(reservation);
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting future reservations by guest ID: " + e.getMessage());
            e.printStackTrace();
        }
        return reservations;
    }
    
    // ============ CHECK RESERVATION NUMBER EXISTS ============
    public boolean reservationNumberExists(String reservationNumber) {
        String sql = "SELECT COUNT(*) FROM reservations WHERE reservation_number = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, reservationNumber);
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    // ============ GET ALL RESERVATIONS - REMOVED STATUS ============
    public List<Reservation> getAllReservations() {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.reservation_number, r.room_type, r.room_number, r.check_in, r.check_out, " +
                     "g.name as guest_name, g.address, g.contact_number, g.guest_id " +
                     "FROM reservations r " +
                     "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                     "ORDER BY r.check_in DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                Reservation reservation = extractReservationFromResultSet(rs);
                if (reservation != null) {
                    reservations.add(reservation);
                }
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return reservations;
    }
    
    // ============ GET RECENT RESERVATIONS - REMOVED STATUS ============
    public List<Reservation> getRecentReservations(int limit) {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.reservation_number, r.room_type, r.room_number, r.check_in, r.check_out, " +
                     "g.name as guest_name, g.address, g.contact_number, g.guest_id " +
                     "FROM reservations r " +
                     "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                     "ORDER BY r.check_in DESC LIMIT ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, limit);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Reservation reservation = extractReservationFromResultSet(rs);
                if (reservation != null) {
                    reservations.add(reservation);
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting recent reservations: " + e.getMessage());
            e.printStackTrace();
        }
        return reservations;
    }
    
    // ============ GET TODAY'S CHECK-INS - REMOVED STATUS ============
    public List<Reservation> getTodaysCheckins() {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.reservation_number, r.room_type, r.room_number, r.check_in, r.check_out, " +
                     "g.name as guest_name, g.address, g.contact_number, g.guest_id " +
                     "FROM reservations r " +
                     "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                     "WHERE DATE(r.check_in) = CURDATE() " +
                     "ORDER BY r.check_in";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                Reservation reservation = extractReservationFromResultSet(rs);
                if (reservation != null) {
                    reservations.add(reservation);
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting today's checkins: " + e.getMessage());
            e.printStackTrace();
        }
        return reservations;
    }
    
    // ============ GET TODAY'S CHECK-OUTS - REMOVED STATUS ============
    public List<Reservation> getTodaysCheckouts() {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.reservation_number, r.room_type, r.room_number, r.check_in, r.check_out, " +
                     "g.name as guest_name, g.address, g.contact_number, g.guest_id " +
                     "FROM reservations r " +
                     "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                     "WHERE DATE(r.check_out) = CURDATE() " +
                     "ORDER BY r.check_out";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                Reservation reservation = extractReservationFromResultSet(rs);
                if (reservation != null) {
                    reservations.add(reservation);
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting today's checkouts: " + e.getMessage());
            e.printStackTrace();
        }
        return reservations;
    }
    
    // ============ GET RESERVATION BY NUMBER - REMOVED STATUS ============
    public Reservation getReservationByNumber(String reservationNumber) {
        String sql = "SELECT r.reservation_number, r.guest_id, r.room_type, r.room_number, r.check_in, r.check_out, " +
                     "g.name as guest_name, g.address, g.contact_number " +
                     "FROM reservations r " +
                     "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                     "WHERE r.reservation_number = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, reservationNumber);
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                return extractReservationFromResultSet(rs);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting reservation by number: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    // ============ SEARCH RESERVATIONS - REMOVED STATUS ============
    public List<Reservation> searchReservations(String searchTerm) {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.reservation_number, r.room_type, r.room_number, r.check_in, r.check_out, " +
                     "g.name as guest_name, g.address, g.contact_number, g.guest_id " +
                     "FROM reservations r " +
                     "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                     "WHERE r.reservation_number LIKE ? OR g.name LIKE ? OR r.room_number LIKE ? " +
                     "ORDER BY r.check_in DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            String searchPattern = "%" + searchTerm + "%";
            ps.setString(1, searchPattern);
            ps.setString(2, searchPattern);
            ps.setString(3, searchPattern);
            
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Reservation reservation = extractReservationFromResultSet(rs);
                reservations.add(reservation);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return reservations;
    }
    
    // ============ GET RESERVATIONS BY ROOM - REMOVED STATUS ============
    public List<Reservation> getReservationsByRoom(String roomNumber) {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.reservation_number, r.room_type, r.room_number, r.check_in, r.check_out, " +
                     "g.name as guest_name, g.address, g.contact_number " +
                     "FROM reservations r " +
                     "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                     "WHERE r.room_number = ? ORDER BY r.check_in DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, roomNumber);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Reservation reservation = extractReservationFromResultSet(rs);
                if (reservation != null) {
                    reservations.add(reservation);
                }
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return reservations;
    }
    
    // ============ DELETE RESERVATION ============
    public boolean deleteReservation(String reservationNumber) {
        String sql = "DELETE FROM reservations WHERE reservation_number = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, reservationNumber);
            int rows = ps.executeUpdate();
            return rows > 0;
            
        } catch (SQLException e) {
            System.err.println("Error deleting reservation: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    // ============ UPDATE RESERVATION - REMOVED STATUS ============
    public boolean updateReservation(Reservation reservation) {
        String sql = "UPDATE reservations SET room_type = ?, check_in = ?, check_out = ?, room_number = ? WHERE reservation_number = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, reservation.getRoomType());
            ps.setDate(2, Date.valueOf(reservation.getCheckIn()));
            ps.setDate(3, Date.valueOf(reservation.getCheckOut()));

            if (reservation.getRoomNumber() != null && !reservation.getRoomNumber().trim().isEmpty()) {
                ps.setString(4, reservation.getRoomNumber().trim());
            } else {
                ps.setNull(4, Types.VARCHAR);
            }

            ps.setString(5, reservation.getReservationNumber());

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // ============ GET TOTAL RESERVATIONS COUNT ============
    public int getTotalReservations() {
        String sql = "SELECT COUNT(*) FROM reservations";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    // ============ GET ACTIVE RESERVATIONS COUNT ============
    public int getActiveReservationsCount() {
        String sql = "SELECT COUNT(*) FROM reservations " +
                     "WHERE CURDATE() BETWEEN check_in AND check_out";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting active reservations count: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
    
    // ============ GET UPCOMING RESERVATIONS COUNT ============
    public int getUpcomingReservationsCount() {
        String sql = "SELECT COUNT(*) FROM reservations WHERE check_in > CURDATE()";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting upcoming reservations count: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
    
    // ============ GET COMPLETED RESERVATIONS COUNT ============
    public int getCompletedReservationsCount() {
        String sql = "SELECT COUNT(*) FROM reservations WHERE check_out < CURDATE()";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting completed reservations count: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
    
    // ============ CHECK FOR OVERLAPPING RESERVATION ============
    public boolean hasOverlappingReservation(int guestId, LocalDate checkIn, LocalDate checkOut) {
        String sql = "SELECT COUNT(*) FROM reservations " +
                     "WHERE guest_id = ? " +
                     "AND check_out >= ? " +  // Existing ends after new starts
                     "AND check_in <= ? " +    // Existing starts before new ends
                     "AND check_out >= CURDATE()"; // Only future/active
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, guestId);
            ps.setDate(2, Date.valueOf(checkIn));
            ps.setDate(3, Date.valueOf(checkOut));
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("Error checking overlapping reservation: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    // ============ EXTRACT RESERVATION FROM RESULTSET - REMOVED STATUS ============
    private Reservation extractReservationFromResultSet(ResultSet rs) throws SQLException {
        Reservation reservation = new Reservation();
        
        reservation.setReservationNumber(rs.getString("reservation_number"));
        
        try {
            reservation.setGuestId(rs.getInt("guest_id"));
        } catch (SQLException e) {
            reservation.setGuestId(0);
        }
        
        try {
            reservation.setGuestName(rs.getString("guest_name"));
        } catch (SQLException e) {
            reservation.setGuestName("");
        }
        
        try {
            reservation.setAddress(rs.getString("address"));
        } catch (SQLException e) {
            reservation.setAddress("");
        }
        
        try {
            reservation.setContactNumber(rs.getString("contact_number"));
        } catch (SQLException e) {
            reservation.setContactNumber("");
        }
        
        reservation.setRoomType(rs.getString("room_type"));
        reservation.setRoomNumber(rs.getString("room_number"));
        
        Date checkInDate = rs.getDate("check_in");
        Date checkOutDate = rs.getDate("check_out");
        
        if (checkInDate != null) {
            reservation.setCheckIn(checkInDate.toLocalDate());
        }
        if (checkOutDate != null) {
            reservation.setCheckOut(checkOutDate.toLocalDate());
        }
        
        // Calculate status based on dates instead of database
        if (checkInDate != null && checkOutDate != null) {
            LocalDate today = LocalDate.now();
            LocalDate checkIn = checkInDate.toLocalDate();
            LocalDate checkOut = checkOutDate.toLocalDate();
            
            if (today.isBefore(checkIn)) {
                reservation.setStatus("UPCOMING");
            } else if (!today.isBefore(checkIn) && !today.isAfter(checkOut)) {
                reservation.setStatus("ACTIVE");
            } else {
                reservation.setStatus("COMPLETED");
            }
        }
        
        return reservation;
    }
    
    // ============ PRINT DATABASE STATS ============
    public void printDatabaseStats() {
        System.out.println("\n=== DATABASE STATISTICS ===");
        System.out.println("Total Reservations: " + getTotalReservations());
        System.out.println("Active: " + getActiveReservationsCount());
        System.out.println("Upcoming: " + getUpcomingReservationsCount());
        System.out.println("Completed: " + getCompletedReservationsCount());
        System.out.println("Today's Check-ins: " + getTodaysCheckins().size());
        System.out.println("Today's Check-outs: " + getTodaysCheckouts().size());
        System.out.println("============================\n");
    }
}