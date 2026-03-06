package com.oceanview.dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import com.oceanview.model.Room;
import com.oceanview.model.Reservation;
import java.time.LocalDate;

public class RoomDao {
    
    // ============ GET AVAILABLE ROOMS BY TYPE AND DATES ============
    public List<Room> getAvailableRooms(String roomType, Date checkIn, Date checkOut) {
        List<Room> availableRooms = new ArrayList<>();
        String sql = "SELECT r.* FROM rooms r " +
                    "WHERE r.room_type = ? " +
                    "AND r.status IN ('AVAILABLE', 'BOOKED') " +
                    "AND r.room_number NOT IN (" +
                    "   SELECT DISTINCT room_number FROM reservations " +
                    "   WHERE room_number IS NOT NULL " +
                    "   AND room_number != '' " +
                    "   AND check_in < ? " +  // Existing check-in BEFORE new check-out
                    "   AND check_out > ?" +   // Existing check-out AFTER new check-in
                    ") " +
                    "ORDER BY r.floor, CAST(r.room_number AS UNSIGNED)";
        
        System.out.println("🔍 Checking available rooms for type: " + roomType + 
                           ", from: " + checkIn + " to: " + checkOut);
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, roomType);
            ps.setDate(2, checkOut); // Existing check_in < new check_out
            ps.setDate(3, checkIn);  // Existing check_out > new check_in
            
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Room room = extractRoomFromResultSet(rs);
                availableRooms.add(room);
                System.out.println("✅ Available room: " + room.getRoomNumber());
            }
            
            System.out.println("📊 Total available rooms found: " + availableRooms.size());
            
        } catch (SQLException e) {
            System.err.println("❌ Error in RoomDao.getAvailableRooms: " + e.getMessage());
            e.printStackTrace();
        }
        return availableRooms;
    }
    
    // ============ CHECK ROOM AVAILABILITY (STRICT) ============
    public boolean isRoomAvailable(String roomNumber, Date checkIn, Date checkOut) {
        boolean isAvailable = true;
        
        String sql = "SELECT COUNT(*) FROM reservations " +
                    "WHERE room_number = ? " +
                    "AND check_in < ? " +  // Existing check-in BEFORE new check-out
                    "AND check_out > ?";    // Existing check-out AFTER new check-in
        
        System.out.println("🔍 Checking room " + roomNumber + " availability for " + checkIn + " to " + checkOut);
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, roomNumber);
            ps.setDate(2, checkOut); // check_in < checkOut
            ps.setDate(3, checkIn);  // check_out > checkIn
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                int count = rs.getInt(1);
                if (count > 0) {
                    isAvailable = false;
                    System.out.println("❌ Room " + roomNumber + " is NOT available (found " + count + " conflicting bookings)");
                } else {
                    System.out.println("✅ Room " + roomNumber + " IS available");
                }
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error checking room availability: " + e.getMessage());
            e.printStackTrace();
            isAvailable = false;
        }
        return isAvailable;
    }
    
    // ============ GET BEST AVAILABLE ROOM (AUTO-ASSIGN) ============
    public Room getBestAvailableRoom(String roomType, Date checkIn, Date checkOut) {
        Room room = null;
        String sql = "SELECT r.* FROM rooms r " +
                    "WHERE r.room_type = ? " +
                    "AND r.status IN ('AVAILABLE', 'BOOKED') " +
                    "AND r.room_number NOT IN (" +
                    "   SELECT DISTINCT room_number FROM reservations " +
                    "   WHERE room_number IS NOT NULL " +
                    "   AND room_number != '' " +
                    "   AND check_in < ? " +
                    "   AND check_out > ?" +
                    ") " +
                    "ORDER BY r.floor, CAST(r.room_number AS UNSIGNED) " +
                    "LIMIT 1";
        
        System.out.println("🔍 Finding best available room for type: " + roomType);
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, roomType);
            ps.setDate(2, checkOut);
            ps.setDate(3, checkIn);
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                room = extractRoomFromResultSet(rs);
                System.out.println("✅ Auto-assigned room: " + room.getRoomNumber());
            } else {
                System.out.println("❌ No available rooms for type: " + roomType);
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error getting best available room: " + e.getMessage());
            e.printStackTrace();
        }
        return room;
    }
    
    // ============ UPDATE ROOM STATUS ============
    public boolean updateRoomStatus(String roomNumber, String status) {
        String sql = "UPDATE rooms SET status = ? WHERE room_number = ?";
        System.out.println("🔄 Updating room " + roomNumber + " status to: " + status);
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, roomNumber);
            int rows = ps.executeUpdate();
            
            if (rows > 0) {
                System.out.println("✅ Room " + roomNumber + " status updated to " + status);
            } else {
                System.out.println("❌ Room " + roomNumber + " not found");
            }
            return rows > 0;
            
        } catch (SQLException e) {
            System.err.println("❌ Error updating room status: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    // ============ GET TOTAL ROOMS COUNT ============
    public int getTotalRoomsCount() {
        int count = 0;
        String sql = "SELECT COUNT(*) FROM rooms";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            if (rs.next()) {
                count = rs.getInt(1);
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error getting total rooms count: " + e.getMessage());
            e.printStackTrace();
        }
        return count;
    }
    
    // ============ GET AVAILABLE ROOMS COUNT ============
    public int getAvailableRoomsCount() {
        int count = 0;
        String sql = "SELECT COUNT(*) FROM rooms WHERE status = 'AVAILABLE'";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            if (rs.next()) {
                count = rs.getInt(1);
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error getting available rooms count: " + e.getMessage());
            e.printStackTrace();
        }
        return count;
    }
    
    // ============ FIXED: GET OCCUPIED ROOMS COUNT (USING DATE LOGIC ONLY - NO CHECKOUTS TABLE) ============
    public int getOccupiedRoomsCount() {
        int count = 0;
        // Count rooms that have active reservations where guest is currently staying
        // This uses ONLY date logic - rooms are considered occupied if:
        // 1. Check-in date is today or in the past (guest has arrived)
        // 2. Check-out date is today or in the future (guest hasn't left yet)
        String sql = "SELECT COUNT(DISTINCT room_number) FROM reservations " +
                    "WHERE room_number IS NOT NULL " +
                    "AND room_number != '' " +
                    "AND check_in <= CURDATE() " + // Guest has arrived
                    "AND check_out >= CURDATE()";   // Guest hasn't left yet (includes today)
        
        System.out.println("🔍 Counting occupied rooms based on date logic...");
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                count = rs.getInt(1);
            }
            
            System.out.println("✅ Found " + count + " occupied rooms (check-in <= today <= check-out)");
            
            // Log details of occupied rooms for debugging
            if (count > 0) {
                logOccupiedRoomsDetails(conn);
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error getting occupied rooms count: " + e.getMessage());
            e.printStackTrace();
        }
        
        return count;
    }
    
    // ============ GET OCCUPIED ROOMS COUNT WITH SESSION DATA (MORE ACCURATE) ============
    public int getOccupiedRoomsCountWithSession(java.util.Map<String, java.time.LocalDate> checkOuts) {
        int count = 0;
        
        String sql = "SELECT room_number, reservation_number, check_in, check_out FROM reservations " +
                    "WHERE room_number IS NOT NULL " +
                    "AND room_number != '' " +
                    "AND check_in <= CURDATE()"; // Guest has arrived
        
        System.out.println("🔍 Counting occupied rooms with session data...");
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                String roomNumber = rs.getString("room_number");
                String reservationNumber = rs.getString("reservation_number");
                Date checkOutDate = rs.getDate("check_out");
                
                // Check if this reservation is checked out (using session data)
                boolean isCheckedOut = checkOuts != null && checkOuts.containsKey(reservationNumber);
                
                if (!isCheckedOut) {
                    // Guest hasn't checked out - room is occupied
                    count++;
                    System.out.println("   ✅ Room " + roomNumber + " is occupied (Res: " + reservationNumber + ")");
                }
            }
            
            System.out.println("✅ Total occupied rooms (with session): " + count);
            
        } catch (SQLException e) {
            System.err.println("❌ Error getting occupied rooms count with session: " + e.getMessage());
            e.printStackTrace();
        }
        
        return count;
    }
    
    // ============ HELPER: LOG OCCUPIED ROOMS DETAILS ============
    private void logOccupiedRoomsDetails(Connection conn) {
        String detailSql = "SELECT r.room_number, res.reservation_number, " +
                           "res.check_in, res.check_out, g.name as guest_name " +
                           "FROM reservations res " +
                           "JOIN rooms r ON res.room_number = r.room_number " +
                           "JOIN guests g ON res.guest_id = g.guest_id " +
                           "WHERE res.room_number IS NOT NULL " +
                           "AND res.room_number != '' " +
                           "AND res.check_in <= CURDATE() " +
                           "AND res.check_out >= CURDATE()";
        
        try (PreparedStatement ps = conn.prepareStatement(detailSql);
             ResultSet rs = ps.executeQuery()) {
            
            System.out.println("📋 Occupied Rooms Details:");
            boolean found = false;
            while (rs.next()) {
                found = true;
                String roomNum = rs.getString("room_number");
                String guestName = rs.getString("guest_name");
                Date checkIn = rs.getDate("check_in");
                Date checkOut = rs.getDate("check_out");
                
                System.out.println("   🏨 Room " + roomNum + 
                                 " - Guest: " + guestName + 
                                 " (Check-in: " + checkIn + 
                                 ", Check-out: " + checkOut + ")");
            }
            if (!found) {
                System.out.println("   No occupied rooms found");
            }
        } catch (SQLException e) {
            System.err.println("❌ Error logging occupied rooms details: " + e.getMessage());
        }
    }
    
    // ============ DEBUG METHOD: CHECK ALL RESERVATIONS ============
    public void debugAllReservations() {
        String sql = "SELECT r.room_number, res.reservation_number, res.check_in, res.check_out " +
                     "FROM reservations res " +
                     "LEFT JOIN rooms r ON res.room_number = r.room_number " +
                     "WHERE res.room_number IS NOT NULL " +
                     "AND res.room_number != '' " +
                     "ORDER BY res.check_in";
        
        System.out.println("\n=== DEBUG: All Reservations with Rooms ===");
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            LocalDate today = LocalDate.now();
            boolean found = false;
            
            while (rs.next()) {
                found = true;
                String roomNum = rs.getString("room_number");
                String resNum = rs.getString("reservation_number");
                Date checkIn = rs.getDate("check_in");
                Date checkOut = rs.getDate("check_out");
                
                boolean isOccupied = !checkIn.toLocalDate().isAfter(today) && 
                                    !checkOut.toLocalDate().isBefore(today);
                
                System.out.println("Room " + roomNum + 
                                 " - Res: " + resNum + 
                                 " (" + checkIn + " to " + checkOut + ")" +
                                 " - " + (isOccupied ? "🟢 OCCUPIED" : "⚪ NOT OCCUPIED"));
            }
            
            if (!found) {
                System.out.println("No reservations with rooms found");
            }
        } catch (SQLException e) {
            System.err.println("❌ Error in debug: " + e.getMessage());
            e.printStackTrace();
        }
        System.out.println("=========================================\n");
    }
    
    // ============ GET ROOMS BY TYPE ============
    public List<Room> getRoomsByType(String roomType) {
        List<Room> rooms = new ArrayList<>();
        String sql = "SELECT * FROM rooms WHERE room_type = ? ORDER BY room_number";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, roomType);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Room room = extractRoomFromResultSet(rs);
                rooms.add(room);
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error getting rooms by type: " + e.getMessage());
            e.printStackTrace();
        }
        return rooms;
    }
    
    // ============ GET ROOM BY NUMBER ============
    public Room getRoomByNumber(String roomNumber) {
        Room room = null;
        String sql = "SELECT * FROM rooms WHERE room_number = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, roomNumber);
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                room = extractRoomFromResultSet(rs);
                System.out.println("✅ Found room: " + roomNumber + " (Status: " + room.getStatus() + ")");
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error getting room by number: " + e.getMessage());
            e.printStackTrace();
        }
        return room;
    }
    
    // ============ GET ALL ROOMS ============
    public List<Room> getAllRooms() {
        List<Room> rooms = new ArrayList<>();
        String sql = "SELECT * FROM rooms ORDER BY floor, CAST(room_number AS UNSIGNED)";
        
        try (Connection conn = DBConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Room room = extractRoomFromResultSet(rs);
                rooms.add(room);
            }
            System.out.println("📊 Loaded " + rooms.size() + " rooms from database");
            
        } catch (SQLException e) {
            System.err.println("❌ Error getting all rooms: " + e.getMessage());
            e.printStackTrace();
        }
        return rooms;
    }
    
    // ============ ADD NEW ROOM ============
    public boolean addRoom(Room room) {
        String sql = "INSERT INTO rooms (room_number, room_type, status, floor, features, rate) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, room.getRoomNumber());
            ps.setString(2, room.getRoomType());
            ps.setString(3, room.getStatus() != null ? room.getStatus() : "AVAILABLE");
            ps.setInt(4, room.getFloor());
            ps.setString(5, room.getFeatures());
            ps.setDouble(6, room.getRate());
            
            boolean success = ps.executeUpdate() > 0;
            if (success) {
                System.out.println("✅ Added new room: " + room.getRoomNumber());
            }
            return success;
            
        } catch (SQLException e) {
            System.err.println("❌ Error adding room: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    // ============ UPDATE ROOM ============
    public boolean updateRoom(Room room) {
        String sql = "UPDATE rooms SET room_type = ?, status = ?, floor = ?, features = ?, rate = ? " +
                     "WHERE room_number = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, room.getRoomType());
            ps.setString(2, room.getStatus());
            ps.setInt(3, room.getFloor());
            ps.setString(4, room.getFeatures());
            ps.setDouble(5, room.getRate());
            ps.setString(6, room.getRoomNumber());
            
            boolean success = ps.executeUpdate() > 0;
            if (success) {
                System.out.println("✅ Updated room: " + room.getRoomNumber());
            }
            return success;
            
        } catch (SQLException e) {
            System.err.println("❌ Error updating room: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    // ============ DELETE ROOM ============
    public boolean deleteRoom(String roomNumber) {
        // First check if room has any reservations
        String checkSql = "SELECT COUNT(*) FROM reservations WHERE room_number = ?";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
            
            checkPs.setString(1, roomNumber);
            ResultSet rs = checkPs.executeQuery();
            if (rs.next() && rs.getInt(1) > 0) {
                System.err.println("❌ Cannot delete room " + roomNumber + " - has existing reservations");
                return false;
            }
            
            // No reservations, safe to delete
            String deleteSql = "DELETE FROM rooms WHERE room_number = ?";
            try (PreparedStatement deletePs = conn.prepareStatement(deleteSql)) {
                deletePs.setString(1, roomNumber);
                boolean success = deletePs.executeUpdate() > 0;
                if (success) {
                    System.out.println("✅ Deleted room: " + roomNumber);
                }
                return success;
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error deleting room: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }
    
    // ============ CHECK IF ROOM HAS CONFLICTING RESERVATIONS ============
    public boolean hasConflictingReservations(String roomNumber, Date checkIn, Date checkOut, String excludeReservationNumber) {
        String sql = "SELECT COUNT(*) FROM reservations " +
                    "WHERE room_number = ? " +
                    "AND check_in < ? " +
                    "AND check_out > ?";
        
        if (excludeReservationNumber != null && !excludeReservationNumber.isEmpty()) {
            sql += " AND reservation_number != ?";
        }
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, roomNumber);
            ps.setDate(2, checkOut);
            ps.setDate(3, checkIn);
            
            if (excludeReservationNumber != null && !excludeReservationNumber.isEmpty()) {
                ps.setString(4, excludeReservationNumber);
            }
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error checking conflicting reservations: " + e.getMessage());
            e.printStackTrace();
        }
        return true;
    }
    
    // ============ GET ROOM OCCUPANCY HISTORY ============
    public List<Reservation> getRoomOccupancyHistory(String roomNumber) {
        List<Reservation> reservations = new ArrayList<>();
        ReservationDao reservationDao = new ReservationDao();
        
        try {
            reservations = reservationDao.getReservationsByRoom(roomNumber);
        } catch (Exception e) {
            System.err.println("❌ Error getting room occupancy history: " + e.getMessage());
            e.printStackTrace();
        }
        
        return reservations;
    }
    
    // ============ EXTRACT ROOM FROM RESULTSET ============
    private Room extractRoomFromResultSet(ResultSet rs) throws SQLException {
        Room room = new Room();
        room.setRoomNumber(rs.getString("room_number"));
        room.setRoomType(rs.getString("room_type"));
        room.setStatus(rs.getString("status"));
        room.setFloor(rs.getInt("floor"));
        room.setFeatures(rs.getString("features"));
        room.setRate(rs.getDouble("rate"));
        return room;
    }
    
    // ============ BULK UPDATE ROOM STATUSES ============
    public void refreshAllRoomStatuses() {
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);
            
            // First reset all rooms to AVAILABLE
            String resetSql = "UPDATE rooms SET status = 'AVAILABLE'";
            try (PreparedStatement resetPs = conn.prepareStatement(resetSql)) {
                resetPs.executeUpdate();
                System.out.println("🔄 Reset all room statuses to AVAILABLE");
            }
            
            // Set BOOKED for future reservations
            String bookSql = "UPDATE rooms r " +
                            "SET r.status = 'BOOKED' " +
                            "WHERE r.room_number IN (" +
                            "   SELECT DISTINCT room_number FROM reservations " +
                            "   WHERE room_number IS NOT NULL " +
                            "   AND room_number != '' " +
                            "   AND check_in > CURDATE()" +
                            ")";
            
            try (PreparedStatement bookPs = conn.prepareStatement(bookSql)) {
                int booked = bookPs.executeUpdate();
                System.out.println("✅ Set " + booked + " rooms as BOOKED (future)");
            }
            
            // Set OCCUPIED for current stays (guest has arrived and hasn't left)
            String occupySql = "UPDATE rooms r " +
                              "SET r.status = 'OCCUPIED' " +
                              "WHERE r.room_number IN (" +
                              "   SELECT DISTINCT room_number FROM reservations " +
                              "   WHERE room_number IS NOT NULL " +
                              "   AND room_number != '' " +
                              "   AND check_in <= CURDATE() " +
                              "   AND check_out >= CURDATE()" +
                              ")";
            
            try (PreparedStatement occupyPs = conn.prepareStatement(occupySql)) {
                int occupied = occupyPs.executeUpdate();
                System.out.println("✅ Set " + occupied + " rooms as OCCUPIED (current stays)");
            }
            
            conn.commit();
            System.out.println("✅ Room statuses refreshed successfully");
            
        } catch (SQLException e) {
            System.err.println("❌ Error refreshing room statuses: " + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    System.err.println("❌ Error rolling back: " + ex.getMessage());
                }
            }
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    System.err.println("❌ Error closing connection: " + e.getMessage());
                }
            }
        }
    }
    
    // ============ GET DETAILED OCCUPANCY INFO ============
    public List<String> getOccupiedRoomsDetails() {
        List<String> occupiedRooms = new ArrayList<>();
        String sql = "SELECT DISTINCT r.room_number, g.name as guest_name, res.check_in, res.check_out " +
                    "FROM rooms r " +
                    "JOIN reservations res ON r.room_number = res.room_number " +
                    "JOIN guests g ON res.guest_id = g.guest_id " +
                    "WHERE res.room_number IS NOT NULL " +
                    "AND res.room_number != '' " +
                    "AND res.check_in <= CURDATE() " +
                    "AND res.check_out >= CURDATE() " +
                    "ORDER BY r.room_number";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                String details = "Room " + rs.getString("room_number") + 
                               " - Guest: " + rs.getString("guest_name") +
                               " (Check-in: " + rs.getDate("check_in") + 
                               ", Check-out: " + rs.getDate("check_out") + ")";
                occupiedRooms.add(details);
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error getting occupied rooms details: " + e.getMessage());
            e.printStackTrace();
        }
        return occupiedRooms;
    }
}