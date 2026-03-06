package com.oceanview.controller;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.oceanview.model.Reservation;
import com.oceanview.service.BillingService;
import com.oceanview.service.BillingService.BillCalculation;
import com.oceanview.service.ReservationService;
import com.oceanview.service.ServiceResult;

@WebServlet("/generate-bill")
public class GenerateBillServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private BillingService billingService;
    private ReservationService reservationService;
    
    @Override
    public void init() {
        billingService = new BillingService();
        reservationService = new ReservationService();
        System.out.println("✅ GenerateBillServlet initialized");
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("\n=== GENERATE BILL SERVLET ===");
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String username = (String) session.getAttribute("username");
        String reservationNumber = request.getParameter("number");
        
        System.out.println("Reservation: " + reservationNumber);
        
        if (reservationNumber == null || reservationNumber.trim().isEmpty()) {
            response.sendRedirect("view-reservations?type=error&message=Reservation+number+required");
            return;
        }
        
        try {
            // Get reservation
            ServiceResult<Reservation> result = reservationService.getReservationByNumber(reservationNumber);
            
            if (!result.isSuccess() || result.getData() == null) {
                response.sendRedirect("view-reservations?type=error&message=Reservation+not+found");
                return;
            }
            
            Reservation reservation = result.getData();
            
            // ============ CHECK BILL AND CHECK-OUT STATUS FROM SESSION ============
            Map<String, Boolean> billsGenerated = (Map<String, Boolean>) session.getAttribute("billsGenerated");
            if (billsGenerated == null) {
                billsGenerated = new HashMap<>();
            }
            
            Map<String, java.time.LocalDate> checkOuts = (Map<String, java.time.LocalDate>) session.getAttribute("checkOuts");
            if (checkOuts == null) {
                checkOuts = new HashMap<>();
            }
            
            boolean hasBill = billsGenerated.containsKey(reservationNumber);
            boolean hasCheckedOut = checkOuts.containsKey(reservationNumber);
            
            System.out.println("Has Bill: " + hasBill);
            System.out.println("Has Checked Out: " + hasCheckedOut);
            
            // Calculate bill
            BillCalculation bill = billingService.calculateBill(reservationNumber);
            
            // Track bill in session if this is a new generation
            String action = request.getParameter("action");
            if (!hasBill || "generate".equals(action)) {
                billsGenerated.put(reservationNumber, true);
                session.setAttribute("billsGenerated", billsGenerated);
                hasBill = true;
                System.out.println("✅ New bill generated for: " + reservationNumber);
            }
            
            // Set attributes for JSP
            request.setAttribute("username", username);
            request.setAttribute("reservation", bill.reservation);
            request.setAttribute("nights", bill.nights);
            request.setAttribute("roomRate", bill.roomRate);
            request.setAttribute("roomTotal", bill.roomTotal);
            request.setAttribute("tax", bill.tax);
            request.setAttribute("totalBill", bill.totalBill);
            request.setAttribute("bill", bill);
            request.setAttribute("billingDate", java.time.LocalDate.now());
            request.setAttribute("generatedBy", username);
            
            // ============ IMPORTANT: Pass bill and check-out status to JSP ============
            request.setAttribute("hasBill", hasBill);
            request.setAttribute("hasCheckedOut", hasCheckedOut);
            
            // Forward to bill.jsp
            request.getRequestDispatcher("/bill.jsp").forward(request, response);
            
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("view-reservations?type=error&message=Error+generating+bill");
        }
    }
}