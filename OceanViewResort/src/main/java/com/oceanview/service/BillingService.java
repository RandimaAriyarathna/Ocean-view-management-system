package com.oceanview.service;

import com.oceanview.dao.ReservationDao;
import com.oceanview.model.Reservation;
import java.time.temporal.ChronoUnit;
import java.time.LocalDate;

public class BillingService {
    
    private ReservationDao reservationDao;
    private static final double TAX_RATE = 0.15; // 15% VAT
    
    public BillingService() {
        this.reservationDao = new ReservationDao();
        System.out.println("✅ BillingService initialized");
    }
    
    /**
     * Calculate bill for a reservation
     */
    public BillCalculation calculateBill(String reservationNumber) {
        System.out.println("🔍 BillingService.calculateBill for: " + reservationNumber);
        
        Reservation reservation = reservationDao.getReservationByNumber(reservationNumber);
        
        if (reservation == null) {
            System.err.println("❌ Reservation not found: " + reservationNumber);
            throw new IllegalArgumentException("Reservation not found");
        }
        
        System.out.println("✅ Reservation loaded: " + reservation.getReservationNumber());
        System.out.println("   Guest: " + reservation.getGuestName());
        System.out.println("   Check-in: " + reservation.getCheckIn());
        System.out.println("   Check-out: " + reservation.getCheckOut());
        
        // ============ VALIDATION: Check if reservation is eligible for billing ============
        LocalDate today = LocalDate.now();
        LocalDate checkIn = reservation.getCheckIn();
        LocalDate checkOut = reservation.getCheckOut();
        
        // Determine status for better error message
        String status;
        if (today.isBefore(checkIn)) {
            status = "UPCOMING";
        } else if (!today.isBefore(checkIn) && !today.isAfter(checkOut)) {
            status = "ACTIVE";
        } else {
            status = "COMPLETED";
        }
        
        // Get billing status from reservation
        String billingStatus = reservation.getBillingStatus();
        if (billingStatus == null) billingStatus = "PENDING";
        
        System.out.println("   Current Status: " + status);
        System.out.println("   Billing Status: " + billingStatus);
        
        // Check if bill already exists
        if ("GENERATED".equals(billingStatus) || "PAID".equals(billingStatus)) {
            throw new IllegalArgumentException("Bill already " + billingStatus.toLowerCase() + 
                " for this reservation");
        }
        
        // Allow bill generation for ACTIVE reservations (during stay) or after checkout
        boolean canGenerateBill = "ACTIVE".equals(status) || "COMPLETED".equals(status);
        
        if (!canGenerateBill) {
            if ("UPCOMING".equals(status)) {
                long daysUntilCheckin = ChronoUnit.DAYS.between(today, checkIn);
                String errorMessage = "Bill cannot be generated for UPCOMING reservations. " +
                    "Guest checks in on " + checkIn.toString() + 
                    " (" + daysUntilCheckin + " day(s) from now)";
                throw new IllegalArgumentException(errorMessage);
            } else {
                String errorMessage = "Reservation is not eligible for billing (Status: " + status + ")";
                throw new IllegalArgumentException(errorMessage);
            }
        }
        
        // If active, calculate nights up to today (partial billing)
        long nights;
        if ("ACTIVE".equals(status)) {
            // For active stays, bill up to today
            nights = ChronoUnit.DAYS.between(checkIn, today);
            if (nights < 1) nights = 1; // Minimum 1 night if checked in today
            System.out.println("   Partial billing: " + nights + " nights up to today");
        } else {
            // For completed stays, bill full stay
            nights = ChronoUnit.DAYS.between(checkIn, checkOut);
            System.out.println("   Full billing: " + nights + " nights");
        }
        
        // ============ PROCEED WITH BILL CALCULATION ============
        double roomRate = getRoomRate(reservation.getRoomType());
        double roomTotal = nights * roomRate;
        double tax = roomTotal * TAX_RATE;
        double totalBill = roomTotal + tax;
        
        System.out.println("✅ Bill calculated:");
        System.out.println("   Nights: " + nights);
        System.out.println("   Rate: Rs. " + String.format("%,.2f", roomRate));
        System.out.println("   Room Total: Rs. " + String.format("%,.2f", roomTotal));
        System.out.println("   Tax (15%): Rs. " + String.format("%,.2f", tax));
        System.out.println("   Total Bill: Rs. " + String.format("%,.2f", totalBill));
        
        return new BillCalculation(
            reservation,
            nights,
            roomRate,
            roomTotal,
            tax,
            totalBill,
            status,
            today
        );
    }
    
    /**
     * Get room rate based on type
     */
    private double getRoomRate(String roomType) {
        if (roomType == null) return 0.00;
        
        switch (roomType) {
            case "Standard": return 25600.00;
            case "Deluxe": return 38400.00;
            case "Suite": return 64000.00;
            default: return 0.00;
        }
    }
    
    /**
     * Inner class for bill calculation results
     */
    public static class BillCalculation {
        public final Reservation reservation;
        public final long nights;
        public final double roomRate;
        public final double roomTotal;
        public final double tax;
        public final double totalBill;
        public final String status;
        public final LocalDate billDate;
        
        public BillCalculation(Reservation res, long nights, double rate, 
                              double total, double tax, double grandTotal,
                              String status, LocalDate billDate) {
            this.reservation = res;
            this.nights = nights;
            this.roomRate = rate;
            this.roomTotal = total;
            this.tax = tax;
            this.totalBill = grandTotal;
            this.status = status;
            this.billDate = billDate;
        }
        
        public String getFormattedRoomRate() {
            return String.format("Rs. %,.2f", roomRate);
        }
        
        public String getFormattedRoomTotal() {
            return String.format("Rs. %,.2f", roomTotal);
        }
        
        public String getFormattedTax() {
            return String.format("Rs. %,.2f", tax);
        }
        
        public String getFormattedTotalBill() {
            return String.format("Rs. %,.2f", totalBill);
        }
        
        // Helper method to check if this is a partial bill (during stay)
        public boolean isPartialBill() {
            return "ACTIVE".equals(status);
        }
        
        // Helper method to get bill type description
        public String getBillTypeDescription() {
            if (isPartialBill()) {
                return "Interim Bill (During Stay)";
            } else {
                return "Final Bill (Checkout)";
            }
        }
    }
}