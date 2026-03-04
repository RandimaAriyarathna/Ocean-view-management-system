package com.oceanview.model;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

public class Reservation {
    private String reservationNumber;
    
    // ============ GUEST FIELDS ============
    private int guestId;
    private String guestName;
    private String address;
    private String contactNumber;
    
    // ============ ROOM FIELDS ============
    private String roomType;
    private String roomNumber;
    
    // ============ RESERVATION FIELDS ============
    private String status;
    private LocalDate checkIn;
    private LocalDate checkOut;
    
    // ============ NEW BILLING FIELDS ============
    private String billingStatus;      // "PENDING", "GENERATED", "PAID"
    private LocalDate actualCheckOut;  // When guest actually checked out
    private LocalDate billingDate;     // When bill was generated
    private Double totalBillAmount;    // Calculated bill amount
    
    // ============ CONSTRUCTORS ============
    public Reservation() {
        // Default constructor with billing defaults
        this.billingStatus = "PENDING";
    }
    
    public Reservation(String reservationNumber, int guestId, String guestName, String roomType, 
                      LocalDate checkIn, LocalDate checkOut) {
        this.reservationNumber = reservationNumber;
        this.guestId = guestId;
        this.guestName = guestName;
        this.roomType = roomType;
        this.checkIn = checkIn;
        this.checkOut = checkOut;
        this.billingStatus = "PENDING";
    }
    
    // ============ GETTERS AND SETTERS ============
    
    // Reservation Number
    public String getReservationNumber() { return reservationNumber; }
    public void setReservationNumber(String reservationNumber) { this.reservationNumber = reservationNumber; }
    
    // Guest ID
    public int getGuestId() { return guestId; }
    public void setGuestId(int guestId) { this.guestId = guestId; }
    
    // Guest Information
    public String getGuestName() { return guestName; }
    public void setGuestName(String guestName) { this.guestName = guestName; }
    
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    
    public String getContactNumber() { return contactNumber; }
    public void setContactNumber(String contactNumber) { this.contactNumber = contactNumber; }
    
    // Room Information
    public String getRoomNumber() { return roomNumber; }
    public void setRoomNumber(String roomNumber) { this.roomNumber = roomNumber; }
    
    public String getRoomType() { return roomType; }
    public void setRoomType(String roomType) { this.roomType = roomType; }
    
    // Status
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    // Dates
    public LocalDate getCheckIn() { return checkIn; }
    public void setCheckIn(LocalDate checkIn) { this.checkIn = checkIn; }
    
    public LocalDate getCheckOut() { return checkOut; }
    public void setCheckOut(LocalDate checkOut) { this.checkOut = checkOut; }
    
    // ============ NEW BILLING GETTERS AND SETTERS ============
    public String getBillingStatus() { return billingStatus; }
    public void setBillingStatus(String billingStatus) { this.billingStatus = billingStatus; }
    
    public LocalDate getActualCheckOut() { return actualCheckOut; }
    public void setActualCheckOut(LocalDate actualCheckOut) { this.actualCheckOut = actualCheckOut; }
    
    public LocalDate getBillingDate() { return billingDate; }
    public void setBillingDate(LocalDate billingDate) { this.billingDate = billingDate; }
    
    public Double getTotalBillAmount() { return totalBillAmount; }
    public void setTotalBillAmount(Double totalBillAmount) { this.totalBillAmount = totalBillAmount; }
    
    // ============ CHECK-OUT HELPER METHODS ============
    
    /**
     * Check if guest has checked out (actual checkout date exists)
     */
    public boolean hasCheckedOut() {
        return actualCheckOut != null;
    }
    
    /**
     * Get the effective checkout date (actual if exists, otherwise scheduled)
     */
    public LocalDate getEffectiveCheckOut() {
        return actualCheckOut != null ? actualCheckOut : checkOut;
    }
    
    /**
     * Check if guest checked out early
     */
    public boolean isEarlyCheckOut() {
        return actualCheckOut != null && actualCheckOut.isBefore(checkOut);
    }
    
    /**
     * Check if guest checked out late
     */
    public boolean isLateCheckOut() {
        return actualCheckOut != null && actualCheckOut.isAfter(checkOut);
    }
    
    // ============ HELPER METHODS ============
    
    /**
     * Calculate number of nights between check-in and check-out
     */
    public long getNights() {
        if (checkIn != null && checkOut != null) {
            return ChronoUnit.DAYS.between(checkIn, checkOut);
        }
        return 0;
    }
    
    /**
     * Calculate actual nights stayed (if checked out early/late)
     */
    public long getActualNights() {
        LocalDate end = actualCheckOut != null ? actualCheckOut : checkOut;
        if (checkIn != null && end != null) {
            return ChronoUnit.DAYS.between(checkIn, end);
        }
        return getNights();
    }
    
    /**
     * Get room rate based on room type (Sri Lankan Rupees)
     */
    public double getRoomRate() {
        switch (roomType) {
            case "Standard": return 25600.00; // Rs. 25,600
            case "Deluxe": return 38400.00;   // Rs. 38,400
            case "Suite": return 64000.00;    // Rs. 64,000
            default: return 0.00;
        }
    }
    
    /**
     * Calculate total room charges without tax
     */
    public double getTotalAmount() {
        return getActualNights() * getRoomRate();
    }
    
    /**
     * Calculate total with 15% VAT
     */
    public double getTotalAmountWithTax() {
        return getTotalAmount() * 1.15;
    }
    
    /**
     * Calculate current reservation status with check-out and billing consideration
     */
    public String calculateStatus() {
        if (checkIn == null || checkOut == null) {
            return "UNKNOWN";
        }
        
        LocalDate today = LocalDate.now();
        
        // ============ CHECK-OUT TAKES PRIORITY ============
        // If guest has checked out, they are no longer in the hotel
        if (hasCheckedOut()) {
            if ("GENERATED".equals(billingStatus)) {
                return "COMPLETED";  // Left and bill generated
            } else {
                return "OVERDUE";     // Left without bill
            }
        }
        
        // ============ NO CHECK-OUT YET ============
        // UPCOMING - Future bookings
        if (today.isBefore(checkIn)) {
            return "UPCOMING";
        }
        
        // CURRENT STAY - Between check-in and check-out
        else if (!today.isBefore(checkIn) && !today.isAfter(checkOut)) {
            if ("GENERATED".equals(billingStatus)) {
                return "INVOICED";    // Bill ready, still in room
            } else {
                return "ACTIVE";       // No bill yet
            }
        }
        
        // PAST STAY - After check-out date but guest hasn't been checked out
        else {
            if ("GENERATED".equals(billingStatus)) {
                return "COMPLETED";    // Should have left, but bill done
            } else {
                return "OVERDUE";       // Should have left, no bill
            }
        }
    }
    
    /**
     * Auto-set status based on current dates, check-out, and billing status
     */
    public void calculateAndSetStatus() {
        this.status = calculateStatus();
    }
    
    // ============ STATUS CHECK METHODS ============
    public boolean isUpcoming() {
        return "UPCOMING".equals(calculateStatus());
    }
    
    public boolean isActive() {
        return "ACTIVE".equals(calculateStatus());
    }
    
    public boolean isInvoiced() {
        return "INVOICED".equals(calculateStatus());
    }
    
    public boolean isOverdue() {
        return "OVERDUE".equals(calculateStatus());
    }
    
    public boolean isCompleted() {
        return "COMPLETED".equals(calculateStatus());
    }
    
    /**
     * Check if guest is currently in the hotel (not checked out)
     */
    public boolean isInHouse() {
        return !hasCheckedOut() && !isUpcoming() && !isCompleted();
    }
    
    /**
     * Check if bill can be generated (Active, Invoiced, or Overdue only)
     */
    public boolean canGenerateBill() {
        String currentStatus = calculateStatus();
        return "ACTIVE".equals(currentStatus) || 
               "INVOICED".equals(currentStatus) || 
               "OVERDUE".equals(currentStatus);
    }
    
    /**
     * Check if guest can be checked out (Active or Invoiced only)
     */
    public boolean canCheckOut() {
        String currentStatus = calculateStatus();
        return "ACTIVE".equals(currentStatus) || "INVOICED".equals(currentStatus);
    }
    
    // ============ BILLING HELPER METHODS ============
    
    /**
     * Generate bill amount (call this when generating bill)
     */
    public double generateBill() {
        this.totalBillAmount = getTotalAmountWithTax();
        this.billingDate = LocalDate.now();
        this.billingStatus = "GENERATED";
        return this.totalBillAmount;
    }
    
    /**
     * Mark as paid
     */
    public void markAsPaid() {
        this.billingStatus = "PAID";
    }
    
    /**
     * Checkout guest (record actual checkout date)
     */
    public void checkout(LocalDate checkoutDate) {
        this.actualCheckOut = checkoutDate;
    }
    
    // ============ FORMATTED DISPLAY METHODS ============
    
    /**
     * Format room rate with currency symbol
     */
    public String getFormattedRate() {
        return String.format("Rs. %,.2f", getRoomRate());
    }
    
    /**
     * Format total amount with currency symbol
     */
    public String getFormattedTotal() {
        return String.format("Rs. %,.2f", getTotalAmount());
    }
    
    /**
     * Format total with tax
     */
    public String getFormattedTotalWithTax() {
        return String.format("Rs. %,.2f", getTotalAmountWithTax());
    }
    
    /**
     * Format bill amount
     */
    public String getFormattedBillAmount() {
        return totalBillAmount != null ? String.format("Rs. %,.2f", totalBillAmount) : "N/A";
    }
    
    /**
     * Format dates for display
     */
    public String getFormattedCheckIn() {
        return checkIn != null ? checkIn.format(java.time.format.DateTimeFormatter.ofPattern("MMM dd, yyyy")) : "N/A";
    }
    
    public String getFormattedCheckOut() {
        return checkOut != null ? checkOut.format(java.time.format.DateTimeFormatter.ofPattern("MMM dd, yyyy")) : "N/A";
    }
    
    public String getFormattedActualCheckOut() {
        return actualCheckOut != null ? actualCheckOut.format(java.time.format.DateTimeFormatter.ofPattern("MMM dd, yyyy")) : "N/A";
    }
    
    public String getFormattedBillingDate() {
        return billingDate != null ? billingDate.format(java.time.format.DateTimeFormatter.ofPattern("MMM dd, yyyy")) : "N/A";
    }
    
    /**
     * Get status badge color class
     */
    public String getStatusBadgeClass() {
        String currentStatus = calculateStatus();
        switch (currentStatus) {
            case "UPCOMING": return "status-upcoming";
            case "ACTIVE": return "status-active";
            case "INVOICED": return "status-invoiced";
            case "OVERDUE": return "status-overdue";
            case "COMPLETED": return "status-completed";
            default: return "status-unknown";
        }
    }
    
    /**
     * Get status icon
     */
    public String getStatusIcon() {
        String currentStatus = calculateStatus();
        switch (currentStatus) {
            case "UPCOMING": return "clock";
            case "ACTIVE": return "sun";
            case "INVOICED": return "file-invoice";
            case "OVERDUE": return "exclamation-triangle";
            case "COMPLETED": return "check-circle";
            default: return "question-circle";
        }
    }
    
    // ============ TO STRING METHOD ============
    
    @Override
    public String toString() {
        return "Reservation{" +
                "reservationNumber='" + reservationNumber + '\'' +
                ", guestId=" + guestId +
                ", guestName='" + guestName + '\'' +
                ", roomType='" + roomType + '\'' +
                ", roomNumber='" + roomNumber + '\'' +
                ", checkIn=" + checkIn +
                ", checkOut=" + checkOut +
                ", actualCheckOut=" + actualCheckOut +
                ", status='" + status + '\'' +
                ", billingStatus='" + billingStatus + '\'' +
                ", totalBillAmount=" + totalBillAmount +
                '}';
    }
}