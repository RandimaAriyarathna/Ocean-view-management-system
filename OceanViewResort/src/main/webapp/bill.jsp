<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.Reservation, java.time.format.DateTimeFormatter, java.text.NumberFormat, java.util.Locale, java.time.LocalDate" %>
<%
    Reservation reservation = (Reservation) request.getAttribute("reservation");
    Long nights = (Long) request.getAttribute("nights");
    Double roomRate = (Double) request.getAttribute("roomRate");
    Double roomTotal = (Double) request.getAttribute("roomTotal");
    Double tax = (Double) request.getAttribute("tax");
    Double totalBill = (Double) request.getAttribute("totalBill");
    
    // Get hasBill and hasCheckedOut from request attributes
    Boolean hasBill = (Boolean) request.getAttribute("hasBill");
    Boolean hasCheckedOut = (Boolean) request.getAttribute("hasCheckedOut");
    
    if (hasBill == null) hasBill = false;
    if (hasCheckedOut == null) hasCheckedOut = false;
    
    if (reservation == null) {
        response.sendRedirect("view-reservations");
        return;
    }
    
    // Check session
    javax.servlet.http.HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy");
    DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    String username = (String) userSession.getAttribute("username");
    
    // Format currency for Sri Lanka
    NumberFormat currencyFormat = NumberFormat.getCurrencyInstance(new Locale("en", "LK"));
    
    // Calculate if check-out is allowed (has bill and not checked out)
    boolean canCheckOut = hasBill && !hasCheckedOut;
    
    // ============ OCEAN THEME COLOR PALETTE ============
    /* Primary Navy: #0B2A4A - Deep ocean depth */
    /* Secondary Teal: #1B5E7A - Rich accent */
    /* Gold Accent: #C9A959 - Premium highlights */
    /* Light Aqua: #E8F0F7 - Soft backgrounds */
    /* Warm White: #F8FAFC - Clean surfaces */
    /* Soft Gray: #64748B - Subtle text */
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invoice - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @media print {
            body * { visibility: hidden; }
            .invoice-container, .invoice-container * { visibility: visible; }
            .invoice-container { position: absolute; left: 0; top: 0; width: 100%; }
            .no-print { display: none !important; }
            .print-btn { display: none !important; }
        }
        
        * { 
            margin: 0; 
            padding: 0; 
            box-sizing: border-box; 
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        
        body { 
            background: linear-gradient(135deg, #E8F0F7 0%, #DAE5F0 100%);
            padding: 20px; 
        }
        
        /* ============ OCEAN THEME NAVIGATION ============ */
        .top-nav {
            max-width: 800px;
            margin: 0 auto 20px auto;
            background: #FFFFFF;
            padding: 15px 25px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(11, 42, 74, 0.08);
            display: flex;
            justify-content: space-between;
            align-items: center;
            border: 1px solid #DAE5F0;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .nav-left {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .nav-left i {
            color: #0B2A4A;
            font-size: 24px;
        }
        
        .nav-left h2 {
            color: #0B2A4A;
            font-size: 18px;
            font-weight: 600;
        }
        
        .nav-right {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .nav-btn {
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 500;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s;
            border: none;
            cursor: pointer;
        }
        
        .nav-btn-primary {
            background: linear-gradient(135deg, #0B2A4A, #1B5E7A);
            color: white;
        }
        
        .nav-btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(11, 42, 74, 0.2);
        }
        
        .nav-btn-success {
            background: linear-gradient(135deg, #28a745, #20c997);
            color: white;
        }
        
        .nav-btn-success:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(40, 167, 69, 0.3);
        }
        
        .nav-btn-warning {
            background: linear-gradient(135deg, #C9A959, #b8944f);
            color: #0B2A4A;
        }
        
        .nav-btn-warning:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(201, 169, 89, 0.3);
        }
        
        .nav-btn-secondary {
            background: #F8FAFC;
            color: #0B2A4A;
            border: 1px solid #DAE5F0;
        }
        
        .nav-btn-secondary:hover {
            background: #FFFFFF;
            border-color: #C9A959;
        }
        
        .nav-btn-danger {
            background: linear-gradient(135deg, #dc3545, #ff6b6b);
            color: white;
        }
        
        .nav-btn-danger:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(220, 53, 69, 0.3);
        }
        
        .nav-btn-disabled {
            background: #e2e3e5;
            color: #6c757d;
            border: 1px solid #ced4da;
            cursor: not-allowed;
            opacity: 0.6;
            pointer-events: none;
        }
        
        .checkout-badge {
            background: #28a745;
            color: white;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-left: 10px;
        }
        
        .invoice-container {
            max-width: 800px;
            margin: 0 auto;
            background: #F8FAFC;
            padding: 40px;
            box-shadow: 0 8px 25px rgba(11, 42, 74, 0.15);
            border-radius: 16px;
            border: 1px solid #DAE5F0;
        }
        
        .invoice-header {
            text-align: center;
            margin-bottom: 40px;
            padding-bottom: 20px;
            border-bottom: 2px solid #C9A959;
        }
        
        .invoice-header h1 { 
            color: #0B2A4A; 
            font-size: 32px; 
            margin-bottom: 10px;
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        
        .invoice-header p { 
            color: #1B5E7A; 
            font-size: 16px; 
        }
        
        .company-info {
            text-align: center;
            margin-bottom: 30px;
            color: #0B2A4A;
            line-height: 1.6;
            background: linear-gradient(105deg, #F8FAFC, #E8F0F7);
            padding: 20px;
            border-radius: 12px;
            border: 1px solid #DAE5F0;
        }
        
        .company-info h3 {
            color: #0B2A4A;
            margin-bottom: 10px;
            font-weight: 600;
        }
        
        .company-info p {
            color: #1B5E7A;
        }
        
        .bill-to {
            margin-bottom: 30px;
            padding: 20px;
            background: #FFFFFF;
            border-radius: 12px;
            border: 1px solid #DAE5F0;
            box-shadow: 0 4px 12px rgba(11, 42, 74, 0.06);
        }
        
        .bill-to h3 { 
            color: #0B2A4A; 
            margin-bottom: 15px;
            font-size: 18px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .bill-to h3 i {
            color: #C9A959;
        }
        
        .bill-to p {
            color: #1B5E7A;
            margin-bottom: 5px;
        }
        
        .invoice-details {
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
            padding: 20px;
            background: #FFFFFF;
            border-radius: 12px;
            border: 1px solid #DAE5F0;
            box-shadow: 0 4px 12px rgba(11, 42, 74, 0.06);
        }
        
        .invoice-details p {
            color: #1B5E7A;
            margin-bottom: 8px;
        }
        
        .invoice-details strong {
            color: #0B2A4A;
        }
        
        .invoice-table {
            width: 100%;
            border-collapse: collapse;
            margin: 30px 0;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(11, 42, 74, 0.08);
        }
        
        .invoice-table th {
            background: linear-gradient(135deg, #0B2A4A, #1B5E7A);
            color: #F8FAFC;
            padding: 16px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
            letter-spacing: 0.3px;
        }
        
        .invoice-table td {
            padding: 16px;
            border-bottom: 1px solid #DAE5F0;
            color: #1B5E7A;
        }
        
        .invoice-table tr:last-child td {
            border-bottom: none;
        }
        
        .invoice-table tbody tr:hover {
            background: #E8F0F7;
        }
        
        .amount-cell { 
            text-align: right; 
            font-weight: 600;
            color: #0B2A4A !important;
        }
        
        .total-row {
            background: #E8F0F7;
            font-weight: 700;
            font-size: 18px;
        }
        
        .total-row td { 
            color: #0B2A4A !important;
            border-top: 2px solid #C9A959;
        }
        
        .footer {
            margin-top: 50px;
            text-align: center;
            color: #1B5E7A;
            font-size: 14px;
            border-top: 1px solid #DAE5F0;
            padding-top: 20px;
        }
        
        .footer p {
            margin-bottom: 8px;
        }
        
        .footer strong {
            color: #0B2A4A;
        }
        
        .actions {
            max-width: 800px;
            margin: 20px auto 0 auto;
            text-align: center;
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
        }
        
        .btn {
            padding: 12px 25px;
            border: none;
            border-radius: 30px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
            transition: all 0.3s ease;
            letter-spacing: 0.3px;
        }
        
        .btn-primary { 
            background: linear-gradient(135deg, #0B2A4A, #1B5E7A);
            color: #F8FAFC;
            border: 1px solid #C9A959;
        }
        
        .btn-success { 
            background: linear-gradient(135deg, #1B5E7A, #0B2A4A);
            color: #F8FAFC;
            border: 1px solid #C9A959;
        }
        
        .btn-secondary { 
            background: #F8FAFC;
            color: #0B2A4A;
            border: 1px solid #DAE5F0;
        }
        
        .btn-warning {
            background: linear-gradient(135deg, #C9A959, #b8944f);
            color: #0B2A4A;
        }
        
        .btn-danger {
            background: linear-gradient(135deg, #dc3545, #ff6b6b);
            color: white;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(11, 42, 74, 0.15);
        }
        
        .btn-primary:hover {
            background: linear-gradient(135deg, #1B5E7A, #0B2A4A);
            border-color: #DAE5F0;
        }
        
        .btn-success:hover {
            background: linear-gradient(135deg, #0B2A4A, #1B5E7A);
        }
        
        .btn-secondary:hover {
            background: #FFFFFF;
            border-color: #C9A959;
        }
        
        .currency-symbol {
            color: #C9A959;
            font-weight: 600;
        }
        
        .sri-lanka-stamp {
            text-align: center;
            margin: 20px 0;
            padding: 20px;
            border: 2px dashed #C9A959;
            border-radius: 12px;
            background: linear-gradient(105deg, #F8FAFC, #E8F0F7);
        }
        
        .sri-lanka-stamp h4 {
            color: #0B2A4A;
            margin-bottom: 8px;
            font-weight: 600;
        }
        
        .sri-lanka-stamp h4 i {
            color: #C9A959;
            margin-right: 8px;
        }
        
        .sri-lanka-stamp p {
            color: #1B5E7A;
        }
        
        .payment-terms {
            margin-top: 30px;
            padding: 20px;
            background: #FFFFFF;
            border-radius: 12px;
            border: 1px solid #DAE5F0;
            box-shadow: 0 4px 12px rgba(11, 42, 74, 0.06);
        }
        
        .payment-terms h3 {
            color: #0B2A4A;
            margin-bottom: 15px;
            font-size: 18px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .payment-terms h3 i {
            color: #C9A959;
        }
        
        .payment-terms p {
            color: #1B5E7A;
            margin-bottom: 8px;
        }
        
        .bank-details {
            margin-left: 20px;
            margin-top: 15px;
            padding: 15px;
            background: #E8F0F7;
            border-radius: 8px;
            border-left: 4px solid #C9A959;
        }
        
        .bank-details p {
            color: #0B2A4A;
        }
        
        .bank-details strong {
            color: #1B5E7A;
        }
        
        .important-notes {
            margin-top: 20px;
            padding: 20px;
            background: #E8F0F7;
            border-radius: 12px;
            border-left: 4px solid #C9A959;
        }
        
        .important-notes h4 {
            color: #0B2A4A;
            margin-bottom: 12px;
            font-weight: 600;
        }
        
        .important-notes h4 i {
            color: #C9A959;
            margin-right: 8px;
        }
        
        .important-notes p {
            color: #1B5E7A;
            font-size: 14px;
            line-height: 1.6;
        }
        
        .signature-section {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #DAE5F0;
            display: flex;
            justify-content: space-between;
            gap: 20px;
            flex-wrap: wrap;
        }
        
        .signature-box {
            flex: 1;
            min-width: 200px;
            padding: 10px 20px;
            color: #1B5E7A;
            font-size: 11px;
            border: 1px dashed #C9A959;
            border-radius: 8px;
            background: #F8FAFC;
        }
        
        .signature-box strong {
            color: #0B2A4A;
        }
        
        .print-btn {
            background: #C9A959;
            color: #0B2A4A;
        }
        
        .print-btn:hover {
            background: #b8944f;
        }
        
        @media (max-width: 768px) {
            .top-nav {
                flex-direction: column;
                gap: 10px;
                text-align: center;
            }
            
            .nav-right {
                width: 100%;
                justify-content: center;
            }
            
            .invoice-container {
                padding: 20px;
            }
            
            .invoice-details {
                flex-direction: column;
                gap: 10px;
            }
            
            .actions {
                flex-direction: column;
            }
            
            .btn {
                width: 100%;
                justify-content: center;
            }
            
            .signature-section {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <!-- ============ TOP NAVIGATION (Ocean Theme) with CHECK OUT BUTTON ============ -->
    <div class="top-nav no-print">
        <div class="nav-left">
            <i class="fas fa-umbrella-beach"></i>
            <h2>Ocean View Resort</h2>
            <% if (hasBill) { %>
                <span class="checkout-badge">
                    <i class="fas fa-check-circle"></i> Bill Generated
                </span>
            <% } %>
        </div>
        <div class="nav-right">
            <!-- CHECK OUT BUTTON - Prominently displayed in top right -->
            <% if (canCheckOut) { %>
                <button onclick="checkoutGuest('<%= reservation.getReservationNumber() %>', '<%= reservation.getGuestName() %>')" 
                        class="nav-btn nav-btn-success" 
                        title="Check out this guest">
                    <i class="fas fa-sign-out-alt"></i> CHECK OUT GUEST
                </button>
            <% } else if (hasCheckedOut) { %>
                <span class="nav-btn nav-btn-disabled" title="Guest already checked out">
                    <i class="fas fa-check-double"></i> CHECKED OUT
                </span>
            <% } else { %>
                <span class="nav-btn nav-btn-disabled" title="Generate bill first">
                    <i class="fas fa-ban"></i> CHECK OUT UNAVAILABLE
                </span>
            <% } %>
            
            <a href="billing.jsp" class="nav-btn nav-btn-secondary">
                <i class="fas fa-file-invoice-dollar"></i> Billing
            </a>
            <a href="view-reservations" class="nav-btn nav-btn-secondary">
                <i class="fas fa-list"></i> Reservations
            </a>
            <a href="dashboard.jsp" class="nav-btn nav-btn-primary">
                <i class="fas fa-arrow-left"></i> Dashboard
            </a>
        </div>
    </div>

    <div class="invoice-container">
        <!-- Header with Ocean Theme -->
        <div class="invoice-header">
            <h1><i class="fas fa-file-invoice-dollar" style="color: #C9A959; margin-right: 10px;"></i> TAX INVOICE</h1>
            <p style="color: #1B5E7A;">Ocean View Resort - Official Bill (Sri Lanka)</p>
        </div>
        
        <!-- Company Info with Ocean Colors -->
        <div class="company-info">
            <h3>🌊 Ocean View Resort (Pvt) Ltd</h3>
            <p><i class="fas fa-map-marker-alt" style="color: #C9A959; margin-right: 8px;"></i> 123 Beach Road, Galle, Southern Province, Sri Lanka</p>
            <p><i class="fas fa-phone" style="color: #C9A959; margin-right: 8px;"></i> 📞 +94 91 223 4455 | ✉️ info@oceanviewresort.lk</p>
            <p><i class="fas fa-building" style="color: #C9A959; margin-right: 8px;"></i> VAT Registration No: VAT-REG-1234567 | Business Reg: BN123456789</p>
        </div>
        
        <!-- Sri Lanka Stamp with Ocean Theme -->
        <div class="sri-lanka-stamp">
            <h4><i class="fas fa-stamp"></i> PAYABLE IN SRI LANKAN RUPEES (LKR)</h4>
            <p>This invoice is issued under the Sri Lanka Tourism Development Authority</p>
        </div>
        
        <!-- Invoice Details -->
        <div class="invoice-details">
            <div>
                <p><strong><i class="fas fa-hashtag" style="color: #C9A959; margin-right: 5px;"></i> Invoice #:</strong> INV-<%= reservation.getReservationNumber() %></p>
                <p><strong><i class="fas fa-calendar" style="color: #C9A959; margin-right: 5px;"></i> Invoice Date:</strong> <%= java.time.LocalDate.now().format(dateFormatter) %></p>
                <p><strong><i class="fas fa-clock" style="color: #C9A959; margin-right: 5px;"></i> Payment Due:</strong> Upon Check-in</p>
            </div>
            <div>
                <p><strong><i class="fas fa-tag" style="color: #C9A959; margin-right: 5px;"></i> Reservation #:</strong> <%= reservation.getReservationNumber() %></p>
                <p><strong><i class="fas fa-user" style="color: #C9A959; margin-right: 5px;"></i> Guest Name:</strong> <%= reservation.getGuestName() %></p>
                <p><strong><i class="fas fa-door-closed" style="color: #C9A959; margin-right: 5px;"></i> Room #:</strong> <%= reservation.getRoomNumber() != null ? reservation.getRoomNumber() : "Not Assigned" %></p>
            </div>
        </div>
        
        <!-- Guest Info with Ocean Theme -->
        <div class="bill-to">
            <h3><i class="fas fa-user-circle"></i> Bill To:</h3>
            <p><strong style="color: #0B2A4A;"><%= reservation.getGuestName() %></strong></p>
            <% if (reservation.getAddress() != null && !reservation.getAddress().isEmpty()) { %>
            <p><i class="fas fa-map-pin" style="color: #C9A959; margin-right: 5px;"></i> <%= reservation.getAddress() %></p>
            <% } %>
            <p><i class="fas fa-phone-alt" style="color: #C9A959; margin-right: 5px;"></i> <%= reservation.getContactNumber() %></p>
        </div>
        
        <!-- Items Table with Ocean Theme -->
        <table class="invoice-table">
            <thead>
                <tr>
                    <th>Description</th>
                    <th>Check-in</th>
                    <th>Check-out</th>
                    <th>Nights</th>
                    <th>Rate/Night</th>
                    <th>Amount (LKR)</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><strong><%= reservation.getRoomType() %></strong> Room Accommodation</td>
                    <td><i class="fas fa-calendar" style="color: #C9A959; margin-right: 5px;"></i> <%= reservation.getCheckIn().format(dateFormatter) %></td>
                    <td><i class="fas fa-calendar" style="color: #C9A959; margin-right: 5px;"></i> <%= reservation.getCheckOut().format(dateFormatter) %></td>
                    <td><span style="background: #E8F0F7; padding: 4px 8px; border-radius: 20px;"><i class="fas fa-moon"></i> <%= nights %></span></td>
                    <td class="amount-cell"><%= currencyFormat.format(roomRate) %></td>
                    <td class="amount-cell"><%= currencyFormat.format(roomTotal) %></td>
                </tr>
                
                <!-- Tax Row -->
                <tr>
                    <td colspan="5" style="text-align: right; color: #1B5E7A;"><strong>VAT (15%):</strong></td>
                    <td class="amount-cell"><%= currencyFormat.format(tax) %></td>
                </tr>
                
                <!-- Total Row -->
                <tr class="total-row">
                    <td colspan="5" style="text-align: right;"><strong>TOTAL AMOUNT PAYABLE:</strong></td>
                    <td class="amount-cell"><span style="font-size: 20px;"><%= currencyFormat.format(totalBill) %></span></td>
                </tr>
            </tbody>
        </table>
        
        <!-- Payment Terms with Ocean Theme -->
        <div class="payment-terms">
            <h3><i class="fas fa-credit-card"></i> Payment Terms & Instructions</h3>
            <p>• All amounts are in Sri Lankan Rupees (LKR)</p>
            <p>• Payment due upon check-in</p>
            <p>• Accepted payment methods: Cash (LKR), Credit/Debit Cards, Bank Transfer</p>
            <p>• Bank Transfer Details:</p>
            <div class="bank-details">
                <p><strong>Bank:</strong> Commercial Bank of Sri Lanka</p>
                <p><strong>Account Name:</strong> Ocean View Resort (Pvt) Ltd</p>
                <p><strong>Account No:</strong> 1234567890</p>
                <p><strong>Branch:</strong> Galle Main</p>
                <p><strong>SWIFT Code:</strong> CCEYLKLX</p>
            </div>
        </div>
        
        <!-- Important Notes with Ocean Theme -->
        <div class="important-notes">
            <h4><i class="fas fa-exclamation-circle"></i> Important Notes:</h4>
            <p>
                • 15% VAT is included as per Sri Lankan government regulations<br>
                • Service charge of 10% may apply for additional services<br>
                • Early check-in/late check-out subject to availability and additional charges<br>
                • Prices include breakfast for two persons
            </p>
        </div>
        
        <!-- Footer with Ocean Theme -->
        <div class="footer">
            <p><strong style="color: #0B2A4A;">Thank you for choosing Ocean View Resort! 🌊</strong></p>
            <p>For billing inquiries, please contact: <i class="fas fa-envelope" style="color: #C9A959;"></i> billing@oceanviewresort.lk or call <i class="fas fa-phone" style="color: #C9A959;"></i> +94 91 223 4455 (Ext. 102)</p>
            <p style="margin-top: 10px; font-size: 12px; color: #64748B;">
                <i class="fas fa-clock" style="color: #C9A959;"></i> Invoice generated on <%= java.time.LocalDateTime.now().format(dateTimeFormatter) %> 
                by <i class="fas fa-user" style="color: #C9A959;"></i> <%= username %> | Ref: OVR-BILL-<%= reservation.getReservationNumber() %>
            </p>
            
            <!-- Signature Section -->
            <div class="signature-section">
                <div class="signature-box">
                    <p><strong>Authorized Signature:</strong> ____________________</p>
                </div>
                <div class="signature-box">
                    <p><strong>Guest Signature:</strong> ____________________</p>
                </div>
            </div>
        </div>
    </div>
    
    <!-- ============ ACTION BUTTONS (Ocean Theme) ============ -->
    <div class="actions no-print">
        <button onclick="window.print()" class="btn btn-primary">
            <i class="fas fa-print"></i> Print Invoice
        </button>
        <button onclick="downloadAsPDF()" class="btn btn-warning">
            <i class="fas fa-download"></i> Download PDF
        </button>
        <a href="billing.jsp" class="btn btn-secondary">
            <i class="fas fa-file-invoice-dollar"></i> Billing Center
        </a>
        <a href="view-reservations" class="btn btn-success">
            <i class="fas fa-list"></i> Reservations
        </a>
        <a href="dashboard.jsp" class="btn btn-secondary">
            <i class="fas fa-arrow-left"></i> Dashboard
        </a>
    </div>
    
    <script>
        // ============ CHECK OUT FUNCTION ============
        function checkoutGuest(reservationNumber, guestName) {
            if (confirm('Check out ' + guestName + '?\n\nMake sure bill has been generated first.')) {
                // Show loading state
                const btn = event.target;
                const originalText = btn.innerHTML;
                btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
                btn.disabled = true;
                
                window.location.href = 'checkout-guest?number=' + encodeURIComponent(reservationNumber);
            }
        }
        
        // Keyboard shortcuts
        document.addEventListener('keydown', function(e) {
            // Ctrl+P to print
            if (e.ctrlKey && e.key === 'p') {
                e.preventDefault();
                window.print();
            }
            // Escape to go to billing center
            if (e.key === 'Escape') {
                window.location.href = 'billing.jsp';
            }
            // Ctrl+Shift+C for check out (if available)
            if (e.ctrlKey && e.shiftKey && e.key === 'C') {
                e.preventDefault();
                const checkoutBtn = document.querySelector('.nav-btn-success');
                if (checkoutBtn) {
                    checkoutBtn.click();
                }
            }
        });
        
        function downloadAsPDF() {
            // Show a more professional message
            const downloadMsg = document.createElement('div');
            downloadMsg.style.position = 'fixed';
            downloadMsg.style.top = '20px';
            downloadMsg.style.left = '50%';
            downloadMsg.style.transform = 'translateX(-50%)';
            downloadMsg.style.background = '#0B2A4A';
            downloadMsg.style.color = 'white';
            downloadMsg.style.padding = '12px 24px';
            downloadMsg.style.borderRadius = '8px';
            downloadMsg.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
            downloadMsg.style.zIndex = '9999';
            downloadMsg.style.fontSize = '14px';
            downloadMsg.style.display = 'flex';
            downloadMsg.style.alignItems = 'center';
            downloadMsg.style.gap = '10px';
            downloadMsg.innerHTML = '<i class="fas fa-info-circle"></i> Use Print → Save as PDF to download';
            
            document.body.appendChild(downloadMsg);
            
            setTimeout(() => {
                downloadMsg.style.opacity = '0';
                downloadMsg.style.transition = 'opacity 0.5s';
                setTimeout(() => downloadMsg.remove(), 500);
            }, 3000);
            
            // Optional: Open print dialog which can save as PDF
            setTimeout(() => {
                window.print();
            }, 1000);
        }
        
        // Auto-hide any message divs
        setTimeout(function() {
            document.querySelectorAll('.message').forEach(msg => {
                msg.style.display = 'none';
            });
        }, 5000);
        
        // Show success message if bill was just generated
        window.onload = function() {
            <% if (request.getParameter("generated") != null) { %>
                const successMsg = document.createElement('div');
                successMsg.style.position = 'fixed';
                successMsg.style.top = '20px';
                successMsg.style.left = '50%';
                successMsg.style.transform = 'translateX(-50%)';
                successMsg.style.background = '#28a745';
                successMsg.style.color = 'white';
                successMsg.style.padding = '12px 24px';
                successMsg.style.borderRadius = '8px';
                successMsg.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
                successMsg.style.zIndex = '9999';
                successMsg.style.fontSize = '14px';
                successMsg.style.display = 'flex';
                successMsg.style.alignItems = 'center';
                successMsg.style.gap = '10px';
                successMsg.innerHTML = '<i class="fas fa-check-circle"></i> Bill generated successfully!';
                
                document.body.appendChild(successMsg);
                
                setTimeout(() => {
                    successMsg.style.opacity = '0';
                    successMsg.style.transition = 'opacity 0.5s';
                    setTimeout(() => successMsg.remove(), 500);
                }, 3000);
            <% } %>
        };
    </script>
</body>
</html>