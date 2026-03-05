package com.oceanview.controller;

import java.io.IOException;
import java.net.URLEncoder;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.oceanview.model.Reservation;
import com.oceanview.model.Guest;
import com.oceanview.service.ReservationService;
import com.oceanview.service.ServiceResult;

@WebServlet("/edit-reservation")
public class EditReservationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private ReservationService reservationService;

    @Override
    public void init() {
        reservationService = new ReservationService();
        System.out.println("✅ EditReservationServlet initialized");
    }

    // GET: Show edit form
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String reservationNumber = request.getParameter("number");
        if (reservationNumber == null || reservationNumber.trim().isEmpty()) {
            response.sendRedirect("view-reservations?type=error&message=" +
                                  URLEncoder.encode("Reservation number required", "UTF-8"));
            return;
        }

        try {
            ServiceResult<Reservation> result = reservationService.getReservationByNumber(reservationNumber);

            if (!result.isSuccess() || result.getData() == null) {
                response.sendRedirect("view-reservations?type=error&message=" +
                                      URLEncoder.encode("Reservation not found", "UTF-8"));
                return;
            }

            Reservation reservation = result.getData();
            
            // ============ CHECK IF RESERVATION IS COMPLETED ============
            Map<String, LocalDate> checkOuts = (Map<String, LocalDate>) session.getAttribute("checkOuts");
            boolean hasCheckedOut = checkOuts != null && checkOuts.containsKey(reservationNumber);
            
            LocalDate today = LocalDate.now();
            String currentStatus;
            
            if (hasCheckedOut) {
                currentStatus = "COMPLETED";
            } else if (today.isBefore(reservation.getCheckIn())) {
                currentStatus = "UPCOMING";
            } else if (!today.isBefore(reservation.getCheckIn()) && !today.isAfter(reservation.getCheckOut())) {
                currentStatus = "ACTIVE";
            } else {
                currentStatus = "COMPLETED";
            }
            
            if ("COMPLETED".equals(currentStatus)) {
                response.sendRedirect("view-reservation?number=" + reservationNumber + 
                                      "&type=error&message=" + 
                                      URLEncoder.encode("Cannot edit completed reservations", "UTF-8"));
                return;
            }

            request.setAttribute("reservation", result.getData());

            String type = request.getParameter("type");
            String message = request.getParameter("message");
            if (type != null && message != null) {
                request.setAttribute("messageType", type);
                request.setAttribute("message", java.net.URLDecoder.decode(message, "UTF-8"));
            }

            request.getRequestDispatcher("editReservation.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("view-reservations?type=error&message=" +
                                  URLEncoder.encode("Error loading reservation", "UTF-8"));
        }
    }

    // POST: Process edit form submission
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String reservationNumber = request.getParameter("reservationNumber");
        
        System.out.println("=== EDIT RESERVATION POST ===");
        System.out.println("Reservation Number: " + reservationNumber);

        // ============ CHECK IF RESERVATION IS COMPLETED ============
        Map<String, LocalDate> checkOuts = (Map<String, LocalDate>) session.getAttribute("checkOuts");
        boolean hasCheckedOut = checkOuts != null && checkOuts.containsKey(reservationNumber);
        
        // First, get the existing reservation
        ServiceResult<Reservation> checkResult = reservationService.getReservationByNumber(reservationNumber);
        if (!checkResult.isSuccess() || checkResult.getData() == null) {
            response.sendRedirect("view-reservations?type=error&message=" +
                                  URLEncoder.encode("Reservation not found", "UTF-8"));
            return;
        }
        
        Reservation existingReservation = checkResult.getData();
        LocalDate today = LocalDate.now();
        
        // Check if completed
        boolean isCompleted = hasCheckedOut || today.isAfter(existingReservation.getCheckOut());
        if (isCompleted) {
            response.sendRedirect("view-reservation?number=" + reservationNumber + 
                                  "&type=error&message=" + 
                                  URLEncoder.encode("Cannot edit completed reservations", "UTF-8"));
            return;
        }

        // ============ GET FORM DATA ============
        String roomType = request.getParameter("roomType");
        String roomNumber = request.getParameter("roomNumber");
        String checkIn = request.getParameter("checkIn");
        String checkOut = request.getParameter("checkOut");
        String guestName = request.getParameter("guestName");
        String guestAddress = request.getParameter("address");
        String guestContact = request.getParameter("contactNumber");
        
        // Get guestId
        int guestId = 0;
        try {
            guestId = Integer.parseInt(request.getParameter("guestId"));
        } catch (NumberFormatException e) {
            System.out.println("❌ Invalid guestId format");
        }

        // ============ VALIDATION ============
        // Only validate fields that are actually being updated
        boolean hasError = false;
        String errorMessage = null;
        
        // Validate guest name if provided
        if (guestName == null || guestName.trim().isEmpty()) {
            errorMessage = "Guest name is required";
            hasError = true;
        }
        
        // Validate contact if provided
        else if (guestContact != null && !guestContact.isEmpty() && !guestContact.matches("\\d{10}")) {
            errorMessage = "Contact number must be exactly 10 digits";
            hasError = true;
        }
        
        // Validate dates only if they are provided
        else if (checkIn != null && !checkIn.trim().isEmpty()) {
            try {
                LocalDate.parse(checkIn);
            } catch (DateTimeParseException e) {
                errorMessage = "Invalid check-in date format";
                hasError = true;
            }
        }
        
        else if (checkOut != null && !checkOut.trim().isEmpty()) {
            try {
                LocalDate.parse(checkOut);
            } catch (DateTimeParseException e) {
                errorMessage = "Invalid check-out date format";
                hasError = true;
            }
        }

        if (hasError) {
            response.sendRedirect("edit-reservation?number=" + reservationNumber + 
                                  "&type=error&message=" + 
                                  URLEncoder.encode(errorMessage, "UTF-8"));
            return;
        }

        // ============ PREPARE UPDATED GUEST ============
        Guest updatedGuest = new Guest();
        updatedGuest.setGuestId(guestId);
        updatedGuest.setName(guestName != null ? guestName.trim() : existingReservation.getGuestName());
        updatedGuest.setAddress(guestAddress != null && !guestAddress.trim().isEmpty() ? 
                               guestAddress.trim() : existingReservation.getAddress());
        updatedGuest.setContactNumber(guestContact != null && !guestContact.trim().isEmpty() ? 
                                     guestContact.trim() : existingReservation.getContactNumber());

        // ============ PREPARE UPDATED RESERVATION ============
        Reservation updatedReservation = new Reservation();
        updatedReservation.setReservationNumber(reservationNumber);
        
        // Use existing values if new ones are not provided
        updatedReservation.setRoomType(roomType != null && !roomType.trim().isEmpty() ? 
                                      roomType : existingReservation.getRoomType());
        updatedReservation.setRoomNumber(roomNumber != null && !roomNumber.trim().isEmpty() ? 
                                        roomNumber : existingReservation.getRoomNumber());
        updatedReservation.setGuestId(guestId);

        // Parse and set dates if provided
        try {
            if (checkIn != null && !checkIn.trim().isEmpty()) {
                updatedReservation.setCheckIn(LocalDate.parse(checkIn));
            } else {
                updatedReservation.setCheckIn(existingReservation.getCheckIn());
            }
            
            if (checkOut != null && !checkOut.trim().isEmpty()) {
                updatedReservation.setCheckOut(LocalDate.parse(checkOut));
            } else {
                updatedReservation.setCheckOut(existingReservation.getCheckOut());
            }
            
            // Validate date order if both dates are being updated
            if (checkIn != null && !checkIn.trim().isEmpty() && 
                checkOut != null && !checkOut.trim().isEmpty()) {
                
                if (updatedReservation.getCheckOut().isBefore(updatedReservation.getCheckIn()) ||
                    updatedReservation.getCheckOut().isEqual(updatedReservation.getCheckIn())) {
                    
                    response.sendRedirect("edit-reservation?number=" + reservationNumber + 
                                          "&type=error&message=" + 
                                          URLEncoder.encode("Check-out date must be after check-in date", "UTF-8"));
                    return;
                }
            }
            
        } catch (DateTimeParseException e) {
            response.sendRedirect("edit-reservation?number=" + reservationNumber + 
                                  "&type=error&message=" + 
                                  URLEncoder.encode("Invalid date format", "UTF-8"));
            return;
        }

        // ============ CALL SERVICE TO UPDATE ============
        System.out.println("=== CALLING EDIT RESERVATION SERVICE ===");
        System.out.println("Updating with:");
        System.out.println("  Guest Name: " + updatedGuest.getName());
        System.out.println("  Room Type: " + updatedReservation.getRoomType());
        System.out.println("  Check-in: " + updatedReservation.getCheckIn());
        System.out.println("  Check-out: " + updatedReservation.getCheckOut());

        ServiceResult<Reservation> result =
                reservationService.editReservation(updatedReservation, updatedGuest);

        if (result.isSuccess() && result.getData() != null) {
            System.out.println("✅ SUCCESS - Reservation updated");

            String redirectURL = request.getContextPath() +
                    "/view-reservation?number=" + reservationNumber +
                    "&type=success&message=" +
                    URLEncoder.encode("Reservation updated successfully", "UTF-8");

            response.sendRedirect(redirectURL);

        } else {
            System.out.println("❌ ERROR - " + result.getMessage());

            String redirectURL = request.getContextPath() +
                    "/edit-reservation?number=" + reservationNumber +
                    "&type=error&message=" +
                    URLEncoder.encode(
                            result.getMessage() != null ?
                                    result.getMessage() :
                                    "Failed to update reservation",
                            "UTF-8");

            response.sendRedirect(redirectURL);
        }
    }
}