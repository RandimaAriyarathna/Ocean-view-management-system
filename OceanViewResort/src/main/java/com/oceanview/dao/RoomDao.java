package com.oceanview.dao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import com.oceanview.model.Room;
import com.oceanview.model.Reservation;
import java.time.LocalDate;


public class RoomDao {
    
    // =====================================================
    // GET AVAILABLE ROOMS BY TYPE AND DATES
    // =====================================================
    public List<Room> getAvailableRooms(String roomType, Date checkIn, Date checkOut) {
        List<Room> availableRooms = new ArrayList<>();
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
                    "ORDER BY r.floor, CAST(r.room_number AS UNSIGNED)";
        
        System.out.println("🔍 Checking available rooms | Type: " + roomType + 
                           " | From: " + checkIn + " | To: " + checkOut);
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, roomType);
            ps.setDate(2, checkOut);
            ps.setDate(3, checkIn);
            
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Room room = extractRoomFromResultSet(rs);
                availableRooms.add(room);
                System.out.println("✅ Available room detected: " + room.getRoomNumber());
            }
            
            System.out.println("📊 Total available rooms: " + availableRooms.size());
            
        } catch (SQLException e) {
            System.err.println("❌ Error retrieving available rooms: " + e.getMessage());
            e.printStackTrace();
        }
        return availableRooms;
    }
    
    // =====================================================
    // CHECK ROOM AVAILABILITY
    // =====================================================
    public boolean isRoomAvailable(String roomNumber, Date checkIn, Date checkOut) {
        boolean isAvailable = true;
        
        String sql = "SELECT COUNT(*) FROM reservations " +
                    "WHERE room_number = ? " +
                    "AND check_in < ? " +
                    "AND check_out > ?";
        
        System.out.println("🔍 Checking availability for room " + roomNumber + 
                           " between " + checkIn + " and " + checkOut);
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, roomNumber);
            ps.setDate(2, checkOut);
            ps.setDate(3, checkIn);
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                int count = rs.getInt(1);
                if (count > 0) {
                    isAvailable = false;
                    System.out.println("❌ Room " + roomNumber + " is NOT available");
                } else {
                    System.out.println("✅ Room " + roomNumber + " is available");
                }
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error checking room availability: " + e.getMessage());
            e.printStackTrace();
            isAvailable = false;
        }
        return isAvailable;
    }
    
    // =====================================================
    // GET BEST AVAILABLE ROOM (AUTO ASSIGN)
    // =====================================================
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
        
        System.out.println("🔍 Searching for best available room | Type: " + roomType);
        
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
            System.err.println("❌ Error finding best available room: " + e.getMessage());
            e.printStackTrace();
        }
        return room;
    }
    
    // =====================================================
    // UPDATE ROOM STATUS
    // =====================================================
    public boolean updateRoomStatus(String roomNumber, String status) {
        String sql = "UPDATE rooms SET status = ? WHERE room_number = ?";
        
        System.out.println("🔄 Updating room status | Room: " + roomNumber + 
                           " -> Status: " + status);
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, status);
            ps.setString(2, roomNumber);
            int rows = ps.executeUpdate();
            
            if (rows > 0) {
                System.out.println("✅ Room status updated successfully");
            } else {
                System.out.println("❌ Room not found in database");
            }
            return rows > 0;
            
        } catch (SQLException e) {
            System.err.println("❌ Error updating room status: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }

    // =====================================================
    // EXTRACT ROOM OBJECT FROM RESULTSET
    // =====================================================
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
}
