package com.oceanview.controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Date;
import java.time.LocalDate;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.oceanview.dao.RoomDao;
import com.oceanview.model.Room;

@WebServlet("/available-rooms")
public class AvailableRoomsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private RoomDao roomDao;
    
    @Override
    public void init() {
        roomDao = new RoomDao();
        System.out.println("✅ AvailableRoomsServlet initialized");
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("🔍 AvailableRoomsServlet.doGet() called");
        
        // Check authentication
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            System.out.println("❌ Unauthorized access");
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        // Set response type to JSON
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        // Get parameters
        String roomType = request.getParameter("roomType");
        String checkInStr = request.getParameter("checkIn");
        String checkOutStr = request.getParameter("checkOut");
        
        System.out.println("📥 Parameters - roomType: " + roomType + 
                          ", checkIn: " + checkInStr + ", checkOut: " + checkOutStr);
        
        // Validate parameters
        if (roomType == null || roomType.isEmpty() || 
            checkInStr == null || checkInStr.isEmpty() || 
            checkOutStr == null || checkOutStr.isEmpty()) {
            
            response.getWriter().write("[]");
            return;
        }
        
        try {
            // Parse dates
            LocalDate checkIn = LocalDate.parse(checkInStr);
            LocalDate checkOut = LocalDate.parse(checkOutStr);
            
            // Get available rooms from DAO
            List<Room> availableRooms = roomDao.getAvailableRooms(
                roomType, 
                Date.valueOf(checkIn), 
                Date.valueOf(checkOut)
            );
            
            System.out.println("📊 Found " + availableRooms.size() + " available rooms");
            
            // Build JSON manually (without Gson)
            StringBuilder json = new StringBuilder();
            json.append("[");
            
            for (int i = 0; i < availableRooms.size(); i++) {
                Room room = availableRooms.get(i);
                
                if (i > 0) {
                    json.append(",");
                }
                
                json.append("{");
                json.append("\"roomNumber\":\"").append(escapeJson(room.getRoomNumber())).append("\",");
                json.append("\"roomType\":\"").append(escapeJson(room.getRoomType())).append("\",");
                json.append("\"floor\":").append(room.getFloor()).append(",");
                json.append("\"status\":\"").append(escapeJson(room.getStatus())).append("\",");
                json.append("\"rate\":").append(room.getRate()).append(",");
                json.append("\"features\":\"").append(escapeJson(room.getFeatures() != null ? room.getFeatures() : "Standard amenities")).append("\"");
                json.append("}");
            }
            
            json.append("]");
            
            // Send response
            PrintWriter out = response.getWriter();
            out.write(json.toString());
            out.flush();
            
            System.out.println("📤 Sent JSON response with " + availableRooms.size() + " rooms");
            
        } catch (Exception e) {
            System.err.println("❌ Error in AvailableRoomsServlet: " + e.getMessage());
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("[]");
        }
    }
    
    // Helper method to escape special characters in JSON strings
    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}