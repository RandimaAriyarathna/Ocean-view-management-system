package com.oceanview.service;

import com.oceanview.dao.RoomDao;
import com.oceanview.dao.ReservationDao;
import com.oceanview.model.Room;
import com.oceanview.model.Reservation;
import java.time.LocalDate;
import java.util.List;

public class RoomService {
    
    private RoomDao roomDao;
    private ReservationDao reservationDao;
    
    public RoomService() {
        this.roomDao = new RoomDao();
        this.reservationDao = new ReservationDao();
    }
    
    /**
     * Get all rooms
     */
    public List<Room> getAllRooms() {
        return roomDao.getAllRooms();
    }
    
    /**
     * Get available rooms for specific dates
     */
    public List<Room> getAvailableRooms(String roomType, LocalDate checkIn, LocalDate checkOut) {
        return roomDao.getAvailableRooms(
            roomType,
            java.sql.Date.valueOf(checkIn),
            java.sql.Date.valueOf(checkOut)
        );
    }
    
    /**
     * Check if room is available
     */
    public boolean isRoomAvailable(String roomNumber, LocalDate checkIn, LocalDate checkOut) {
        return roomDao.isRoomAvailable(
            roomNumber,
            java.sql.Date.valueOf(checkIn),
            java.sql.Date.valueOf(checkOut)
        );
    }
    
    /**
     * Get room occupancy statistics
     */
    public RoomOccupancyStats getRoomOccupancyStats() {
        List<Room> allRooms = roomDao.getAllRooms();
        int totalRooms = allRooms.size();
        int occupiedRooms = 0;
        
        LocalDate today = LocalDate.now();
        
        for (Room room : allRooms) {
            List<Reservation> roomReservations = reservationDao.getReservationsByRoom(room.getRoomNumber());
            for (Reservation r : roomReservations) {
                if (!today.isBefore(r.getCheckIn()) && !today.isAfter(r.getCheckOut())) {
                    occupiedRooms++;
                    break;
                }
            }
        }
        
        return new RoomOccupancyStats(totalRooms, occupiedRooms, totalRooms - occupiedRooms);
    }
    
    /**
     * Inner class for room occupancy stats
     */
    public static class RoomOccupancyStats {
        public final int totalRooms;
        public final int occupiedRooms;
        public final int availableRooms;
        
        public RoomOccupancyStats(int total, int occupied, int available) {
            this.totalRooms = total;
            this.occupiedRooms = occupied;
            this.availableRooms = available;
        }
        
        public double getOccupancyRate() {
            return totalRooms > 0 ? (occupiedRooms * 100.0 / totalRooms) : 0;
        }
    }
}