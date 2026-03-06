package com.oceanview.controller;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import com.oceanview.model.Reservation;
import com.oceanview.service.ReservationService;
import com.oceanview.service.ServiceResult;

@WebServlet("/view-reservations")
public class ViewReservationsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private ReservationService reservationService;
    
    @Override
    public void init() {
        reservationService = new ReservationService();
        System.out.println("✅ ViewReservationsServlet initialized");
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("\n=== VIEW RESERVATIONS SERVLET ===");
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            System.out.println("❌ No session, redirecting to login");
            response.sendRedirect("login.jsp");
            return;
        }
        
        String username = (String) session.getAttribute("username");
        System.out.println("User: " + username);
        
        try {
            // ============ TEST DATABASE CONNECTION FIRST ============
            System.out.println("Testing database connection...");
            boolean dbConnected = reservationService.testConnection();
            System.out.println("Database connection: " + (dbConnected ? "✅ OK" : "❌ FAILED"));
            
            if (!dbConnected) {
                System.err.println("❌ Database connection failed!");
                request.setAttribute("error", "Database connection failed. Please check if MySQL is running.");
                request.getRequestDispatcher("viewReservation.jsp").forward(request, response);
                return;
            }
            
            // ============ GET RESERVATIONS ============
            System.out.println("Calling reservationService.getAllReservations()...");
            ServiceResult<List<Reservation>> result = reservationService.getAllReservations();
            
            System.out.println("ServiceResult - Success: " + result.isSuccess());
            System.out.println("ServiceResult - Message: " + result.getMessage());
            
            if (!result.isSuccess()) {
                System.err.println("❌ Service error: " + result.getMessage());
                request.setAttribute("error", result.getMessage());
                request.getRequestDispatcher("viewReservation.jsp").forward(request, response);
                return;
            }
            
            List<Reservation> reservations = result.getData();
            System.out.println("✅ Loaded " + (reservations != null ? reservations.size() : 0) + " reservations");
            
            if (reservations == null) {
                System.err.println("❌ Reservations list is null!");
                request.setAttribute("error", "Received null reservation list from database");
                request.getRequestDispatcher("viewReservation.jsp").forward(request, response);
                return;
            }
            
            // ============ TRACK BILL STATUS FROM SESSION ============
            // Get the bills map from session (simple tracking)
            Map<String, Boolean> billsGenerated = (Map<String, Boolean>) session.getAttribute("billsGenerated");
            
            if (billsGenerated == null) {
                billsGenerated = new HashMap<>();
                session.setAttribute("billsGenerated", billsGenerated);
            }
            
            // Update each reservation with bill status from session
            int billedCount = 0;
            for (Reservation r : reservations) {
                if (billsGenerated.containsKey(r.getReservationNumber())) {
                    // Mark that bill was generated in this session
                    r.setBillingStatus("GENERATED");
                    billedCount++;
                } else {
                    r.setBillingStatus(null); // No bill generated
                }
            }
            System.out.println("✅ Applied bill status from session: " + billedCount + " reservations have bills");
            
            // Calculate stats for the stats row
            Long roomsAssigned = 0L;
            for (Reservation r : reservations) {
                if (r.getRoomNumber() != null && !r.getRoomNumber().isEmpty()) {
                    roomsAssigned++;
                }
            }
            
            // Log first few reservations for debugging
            int count = 0;
            for (Reservation r : reservations) {
                if (count++ < 3) { // Log first 3
                    System.out.println("  - " + r.getReservationNumber() + " | " + 
                                      r.getGuestName() + " | " + r.getRoomType() + 
                                      " | Bill: " + (r.getBillingStatus() != null ? r.getBillingStatus() : "NO"));
                }
            }
            
            // Set attributes for JSP
            request.setAttribute("reservations", reservations);
            request.setAttribute("username", username);
            request.setAttribute("roomsAssigned", roomsAssigned);
            
            // Forward to JSP
            System.out.println("Forwarding to viewReservation.jsp");
            request.getRequestDispatcher("viewReservation.jsp").forward(request, response);
            
        } catch (Exception e) {
            System.err.println("❌ EXCEPTION in ViewReservationsServlet:");
            e.printStackTrace();
            request.setAttribute("error", "System error: " + e.getMessage());
            request.getRequestDispatcher("viewReservation.jsp").forward(request, response);
        }
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        doGet(request, response);
    }
}