package com.oceanview.controller;

import java.io.IOException;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.oceanview.model.Reservation;
import com.oceanview.service.ReservationService;
import com.oceanview.service.ServiceResult;

@WebServlet("/checkout-guest")  // This is the URL to access this servlet
public class CheckOutServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    // Service to handle reservation operations
    private ReservationService reservationService;
    
    // This runs when the servlet is first created
    @Override
    public void init() {
        reservationService = new ReservationService();
        System.out.println("✅ CheckOutServlet is ready to use");
    }
    
    // This runs when someone accesses the servlet via GET request
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("\n=== CHECK-OUT SERVLET STARTED ===");
        
        // ===== STEP 1: Check if user is logged in =====
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            // Not logged in - send to login page
            response.sendRedirect("login.jsp");
            return;
        }
        
        String username = (String) session.getAttribute("username");
        System.out.println("User: " + username);
        
        // ===== STEP 2: Get the reservation number from the URL =====
        // URL will be: checkout-guest?number=RES-123
        String reservationNumber = request.getParameter("number");
        System.out.println("Checking out reservation: " + reservationNumber);
        
        // Check if reservation number was provided
        if (reservationNumber == null || reservationNumber.trim().isEmpty()) {
            response.sendRedirect("view-reservations?type=error&message=Reservation+number+required");
            return;
        }
        
        try {
            // ===== STEP 3: Get the reservation from database =====
            ServiceResult<Reservation> result = reservationService.getReservationByNumber(reservationNumber);
            
            if (!result.isSuccess() || result.getData() == null) {
                // Reservation not found
                response.sendRedirect("view-reservations?type=error&message=Reservation+not+found");
                return;
            }
            
            Reservation reservation = result.getData();
            System.out.println("Found reservation for: " + reservation.getGuestName());
            
            // ===== STEP 4: Check if already checked out =====
            // Get the map of check-outs from session
            Map<String, LocalDate> checkOuts = (Map<String, LocalDate>) session.getAttribute("checkOuts");
            
            if (checkOuts != null && checkOuts.containsKey(reservationNumber)) {
                // Already checked out
                response.sendRedirect("view-reservations?type=error&message=Guest+already+checked+out");
                return;
            }
            
            // ===== STEP 5: Check if reservation can be checked out =====
            String currentStatus = reservation.calculateStatus();
            System.out.println("Current status: " + currentStatus);
            
            // Only ACTIVE or INVOICED reservations can be checked out
            if (!currentStatus.equals("ACTIVE") && !currentStatus.equals("INVOICED")) {
                response.sendRedirect("view-reservations?type=error&message=Cannot+check+out+" + 
                    currentStatus.replace(" ", "+") + "+reservation");
                return;
            }
            
            // ===== STEP 6: Record the check-out =====
            LocalDate today = LocalDate.now();
            
            // Create map if it doesn't exist
            if (checkOuts == null) {
                checkOuts = new HashMap<>();
            }
            
            // Save the check-out date
            checkOuts.put(reservationNumber, today);
            session.setAttribute("checkOuts", checkOuts);
            
            System.out.println("✅ Check-out recorded for: " + reservationNumber + " on " + today);
            
            // ===== STEP 7: Check if early or late check-out =====
            LocalDate scheduledCheckOut = reservation.getCheckOut();
            String checkOutMessage = "Guest+checked+out+successfully";
            
            if (today.isBefore(scheduledCheckOut)) {
                long daysEarly = java.time.temporal.ChronoUnit.DAYS.between(today, scheduledCheckOut);
                checkOutMessage = "Early+check-out+completed+" + daysEarly + "+days+early";
                System.out.println("Early check-out: " + daysEarly + " days early");
            } else if (today.isAfter(scheduledCheckOut)) {
                long daysLate = java.time.temporal.ChronoUnit.DAYS.between(scheduledCheckOut, today);
                checkOutMessage = "Late+check-out+completed+" + daysLate + "+days+late";
                System.out.println("Late check-out: " + daysLate + " days late");
            }
            
            // ===== STEP 8: Redirect back to reservations page with success message =====
            response.sendRedirect("view-reservations?type=success&message=" + checkOutMessage);
            
        } catch (Exception e) {
            // Something went wrong
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("view-reservations?type=error&message=Error+checking+out");
        }
        
        System.out.println("=== CHECK-OUT SERVLET FINISHED ===\n");
    }
}