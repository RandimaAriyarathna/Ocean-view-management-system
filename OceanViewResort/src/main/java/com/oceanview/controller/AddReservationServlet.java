package com.oceanview.controller;

import java.io.IOException;
import java.net.URLEncoder;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.oceanview.model.Guest;
import com.oceanview.model.Reservation;
import com.oceanview.service.ReservationService;
import com.oceanview.service.ServiceResult;

@WebServlet("/add-reservation")
public class AddReservationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private ReservationService reservationService;
    
    @Override
    public void init() {
        reservationService = new ReservationService();
        System.out.println("✅ AddReservationServlet initialized");
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        response.sendRedirect("addReservation.jsp");
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // ============ PREVENT DUPLICATE SUBMISSIONS ============
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            System.out.println("❌ No active session, redirecting to login");
            response.sendRedirect("login.jsp");
            return;
        }
        
        // Check for duplicate submission using form token
        String formToken = request.getParameter("formToken");
        String sessionToken = (String) session.getAttribute("lastFormToken");
        
        if (formToken != null && formToken.equals(sessionToken)) {
            System.out.println("⚠️ DUPLICATE SUBMISSION DETECTED - ignoring");
            response.sendRedirect("dashboard.jsp?type=warning&message=Duplicate+submission+ignored");
            return;
        }
        
        // Store this token in session
        if (formToken != null) {
            session.setAttribute("lastFormToken", formToken);
        }
        
        String username = (String) session.getAttribute("username");
        System.out.println("\n=== ADD RESERVATION REQUEST ===");
        System.out.println("User: " + username);
        System.out.println("Request ID: " + System.currentTimeMillis());
        
        try {
            // ============ GET FORM DATA ============
            String guestName = request.getParameter("guestName");
            String address = request.getParameter("address");
            String contactNumber = request.getParameter("contactNumber");
            String roomType = request.getParameter("roomType");
            String checkInStr = request.getParameter("checkIn");
            String checkOutStr = request.getParameter("checkOut");
            String roomNumber = request.getParameter("roomNumber");
            
            // ============ DEBUG: Print received parameters ============
            System.out.println("\n=== RECEIVED FORM DATA ===");
            System.out.println("guestName: '" + guestName + "'");
            System.out.println("address: '" + address + "'");
            System.out.println("contactNumber: '" + contactNumber + "'");
            System.out.println("roomType: '" + roomType + "'");
            System.out.println("checkInStr: '" + checkInStr + "'");
            System.out.println("checkOutStr: '" + checkOutStr + "'");
            System.out.println("roomNumber: '" + roomNumber + "'");
            
            // ============ VALIDATE REQUIRED FIELDS ============
            if (guestName == null || guestName.trim().isEmpty()) {
                System.out.println("❌ Validation failed: guestName is empty");
                response.sendRedirect("addReservation.jsp?type=error&message=Guest+name+is+required");
                return;
            }
            
            if (contactNumber == null || contactNumber.trim().isEmpty()) {
                System.out.println("❌ Validation failed: contactNumber is empty");
                response.sendRedirect("addReservation.jsp?type=error&message=Contact+number+is+required");
                return;
            }
            
            // Validate contact number format (exactly 10 digits)
            if (!contactNumber.matches("\\d{10}")) {
                System.out.println("❌ Validation failed: contactNumber format invalid");
                response.sendRedirect("addReservation.jsp?type=error&message=Contact+number+must+be+exactly+10+digits");
                return;
            }
            
            if (roomType == null || roomType.trim().isEmpty()) {
                System.out.println("❌ Validation failed: roomType is empty");
                response.sendRedirect("addReservation.jsp?type=error&message=Room+type+is+required");
                return;
            }
            
            if (checkInStr == null || checkInStr.trim().isEmpty()) {
                System.out.println("❌ Validation failed: checkIn is empty");
                response.sendRedirect("addReservation.jsp?type=error&message=Check-in+date+is+required");
                return;
            }
            
            if (checkOutStr == null || checkOutStr.trim().isEmpty()) {
                System.out.println("❌ Validation failed: checkOut is empty");
                response.sendRedirect("addReservation.jsp?type=error&message=Check-out+date+is+required");
                return;
            }
            
            // ============ PARSE DATES ============
            System.out.println("\n=== PARSING DATES ===");
            LocalDate checkIn = LocalDate.parse(checkInStr);
            LocalDate checkOut = LocalDate.parse(checkOutStr);
            System.out.println("Check-in: " + checkIn);
            System.out.println("Check-out: " + checkOut);
            
            // Validate date order
            if (checkOut.isBefore(checkIn) || checkOut.isEqual(checkIn)) {
                System.out.println("❌ Validation failed: check-out must be after check-in");
                response.sendRedirect("addReservation.jsp?type=error&message=Check-out+date+must+be+after+check-in+date");
                return;
            }
            
            // Validate dates are not in the past
            LocalDate today = LocalDate.now();
            if (checkIn.isBefore(today)) {
                System.out.println("❌ Validation failed: check-in date is in the past");
                response.sendRedirect("addReservation.jsp?type=error&message=Check-in+date+cannot+be+in+the+past");
                return;
            }
            
            // ============ CREATE GUEST OBJECT ============
            System.out.println("\n=== CREATING GUEST OBJECT ===");
            Guest guest = new Guest();
            guest.setName(guestName.trim());
            guest.setAddress(address != null ? address.trim() : "");
            guest.setContactNumber(contactNumber.trim());
            guest.setEmail(""); // Optional
            System.out.println("Guest created: " + guest.getName() + ", " + guest.getContactNumber());
            
            // ============ CREATE RESERVATION OBJECT ============
            System.out.println("\n=== CREATING RESERVATION OBJECT ===");
            Reservation reservation = new Reservation();
            reservation.setRoomType(roomType.trim());
            reservation.setCheckIn(checkIn);
            reservation.setCheckOut(checkOut);
            
            // Handle room number (null or empty means auto-assign)
            String finalRoomNumber = null;
            if (roomNumber != null && !roomNumber.trim().isEmpty() && !"AUTO".equals(roomNumber.trim())) {
                finalRoomNumber = roomNumber.trim();
                System.out.println("Room number provided: '" + finalRoomNumber + "'");
            } else {
                System.out.println("No room number provided or AUTO selected - will auto-assign");
            }
            
            // ============ CALL SERVICE ============
            System.out.println("\n=== CALLING RESERVATION SERVICE ===");
            System.out.println("Calling createReservation with:");
            System.out.println("- Guest: " + guest.getName());
            System.out.println("- Room Type: " + reservation.getRoomType());
            System.out.println("- Dates: " + checkIn + " to " + checkOut);
            System.out.println("- Room Number: " + (finalRoomNumber != null ? finalRoomNumber : "AUTO"));
            
            ServiceResult<Reservation> result = reservationService.createReservation(
                reservation, guest, finalRoomNumber
            );
            
            // ============ HANDLE RESULT ============
            System.out.println("\n=== SERVICE RESULT ===");
            System.out.println("Success: " + result.isSuccess());
            System.out.println("Message: " + result.getMessage());
            
            if (result.isSuccess() && result.getData() != null) {
                Reservation savedReservation = result.getData();
                long nights = java.time.temporal.ChronoUnit.DAYS.between(checkIn, checkOut);
                
                String successMessage = "Reservation " + savedReservation.getReservationNumber() + " added successfully!";
                
                if (savedReservation.getRoomNumber() != null && !savedReservation.getRoomNumber().isEmpty()) {
                    successMessage += " Room " + savedReservation.getRoomNumber() + " assigned.";
                } else {
                    successMessage += " Room will be assigned later.";
                }
                
                successMessage += " " + nights + " nights booked.";
                
                System.out.println("✅ Reservation successful!");
                System.out.println("Reservation Number: " + savedReservation.getReservationNumber());
                System.out.println("Assigned Room: " + savedReservation.getRoomNumber());
                System.out.println("Nights: " + nights);
                
                // Encode the message for URL
                String encodedMessage = successMessage.replace(" ", "+");
                
                response.setStatus(HttpServletResponse.SC_FOUND);
                response.sendRedirect("view-reservations?type=success&message=" + encodedMessage);
                
            } else {
                System.out.println("❌ Reservation failed: " + result.getMessage());
                
                // Create a user-friendly error message
                String errorMsg = result.getMessage();
                if (errorMsg != null) {
                    // Make error messages more user-friendly
                    if (errorMsg.contains("Room is not available")) {
                        errorMsg = "The selected room is no longer available. Please go back and choose another room or use auto-assign.";
                    } else if (errorMsg.contains("No Standard rooms available")) {
                        errorMsg = "No Standard rooms are available for the selected dates. Please try different dates or another room type.";
                    } else if (errorMsg.contains("No Deluxe rooms available")) {
                        errorMsg = "No Deluxe rooms are available for the selected dates. Please try different dates or another room type.";
                    } else if (errorMsg.contains("No Suite rooms available")) {
                        errorMsg = "No Suite rooms are available for the selected dates. Please try different dates or another room type.";
                    } else if (errorMsg.contains("Room type mismatch")) {
                        errorMsg = "The selected room type does not match the room you chose. Please select a room of type " + roomType + ".";
                    }
                } else {
                    errorMsg = "Failed to create reservation. Please try again.";
                }
                
                String encodedError = URLEncoder.encode(errorMsg, "UTF-8").replace("+", "%20");
                response.sendRedirect("addReservation.jsp?type=error&message=" + encodedError);
            }
            
        } catch (DateTimeParseException e) {
            System.err.println("❌ Date parsing error: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("addReservation.jsp?type=error&message=Invalid+date+format.+Please+use+YYYY-MM-DD");
            
        } catch (IllegalArgumentException e) {
            System.err.println("❌ Validation error: " + e.getMessage());
            e.printStackTrace();
            String errorMsg = e.getMessage().replace(" ", "+");
            response.sendRedirect("addReservation.jsp?type=error&message=" + errorMsg);
            
        } catch (Exception e) {
            System.err.println("❌ Unexpected error in AddReservationServlet:");
            e.printStackTrace();
            
            String errorMsg = e.getMessage();
            if (errorMsg == null || errorMsg.isEmpty()) {
                errorMsg = "An unexpected error occurred. Please try again.";
            } else {
                errorMsg = errorMsg.replace(" ", "+");
                if (errorMsg.length() > 100) {
                    errorMsg = errorMsg.substring(0, 100) + "...";
                }
            }
            
            response.sendRedirect("addReservation.jsp?type=error&message=Error:" + errorMsg);
        }
        
        System.out.println("=== ADD RESERVATION REQUEST COMPLETE ===\n");
    }
}