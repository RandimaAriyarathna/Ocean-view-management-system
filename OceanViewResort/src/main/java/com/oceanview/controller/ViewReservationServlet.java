package com.oceanview.controller;

import java.io.IOException;
import java.net.URLDecoder;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
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

@WebServlet("/view-reservation")
public class ViewReservationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private ReservationService reservationService;

    @Override
    public void init() {
        reservationService = new ReservationService();
        System.out.println("✅ ViewReservationServlet initialized");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String reservationNumber = request.getParameter("number");
        if (reservationNumber == null || reservationNumber.trim().isEmpty()) {
            request.setAttribute("messageType", "error");
            request.setAttribute("message", "Reservation number is required");
            request.getRequestDispatcher("reservationDetails.jsp").forward(request, response);
            return;
        }

        try {
            ServiceResult<Reservation> result = reservationService.getReservationByNumber(reservationNumber);

            if (!result.isSuccess() || result.getData() == null) {
                request.setAttribute("messageType", "error");
                request.setAttribute("message", "Reservation not found");
                request.getRequestDispatcher("reservationDetails.jsp").forward(request, response);
                return;
            }

            Reservation reservation = result.getData();

            // ============ GET BILL AND CHECK-OUT DATA FROM SESSION ============
            Map<String, Boolean> billsGenerated = (Map<String, Boolean>) session.getAttribute("billsGenerated");
            Map<String, LocalDate> checkOuts = (Map<String, LocalDate>) session.getAttribute("checkOuts");
            
            boolean hasBill = billsGenerated != null && billsGenerated.containsKey(reservationNumber);
            boolean hasCheckedOut = checkOuts != null && checkOuts.containsKey(reservationNumber);
            
            if (hasBill) {
                reservation.setBillingStatus("GENERATED");
            }
            
            if (hasCheckedOut) {
                reservation.setActualCheckOut(checkOuts.get(reservationNumber));
            }

            // Ensure status and derived fields are calculated
            reservation.calculateAndSetStatus();
            long nights = reservation.getNights();

            request.setAttribute("reservation", reservation);
            request.setAttribute("nights", nights);
            request.setAttribute("hasBill", hasBill);
            request.setAttribute("hasCheckedOut", hasCheckedOut);

            // Handle messages from query parameters
            String type = request.getParameter("type");
            String message = request.getParameter("message");
            if (type != null && message != null) {
                request.setAttribute("messageType", type);
                request.setAttribute("message", URLDecoder.decode(message, "UTF-8"));
            }

            request.getRequestDispatcher("reservationDetails.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("messageType", "error");
            request.setAttribute("message", "Error loading reservation");
            request.getRequestDispatcher("reservationDetails.jsp").forward(request, response);
        }
    }
}