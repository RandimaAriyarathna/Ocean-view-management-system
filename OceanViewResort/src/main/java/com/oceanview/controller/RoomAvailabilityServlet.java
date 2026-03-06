package com.oceanview.controller;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.oceanview.dao.RoomDao;
import com.oceanview.dao.ReservationDao;
import com.oceanview.model.Room;

@WebServlet("/room-availability")
public class RoomAvailabilityServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private RoomDao roomDao;
    private ReservationDao reservationDao;

    @Override
    public void init() throws ServletException {
        // Initialize DAOs once
        roomDao = new RoomDao();
        reservationDao = new ReservationDao();
        System.out.println("✅ RoomAvailabilityServlet initialized");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("🔍 RoomAvailabilityServlet.doGet() called");
        
        // --- 1. Check authentication ---
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            System.out.println("❌ Unauthorized access, redirecting to login");
            response.sendRedirect("login.jsp");
            return;
        }

        // --- 2. Determine start date for room view ---
        String startDateParam = request.getParameter("startDate");
        LocalDate startDate;
        if (startDateParam != null && !startDateParam.isEmpty()) {
            try {
                startDate = LocalDate.parse(startDateParam);
            } catch (Exception e) {
                System.err.println("❌ Invalid startDate parameter: " + startDateParam);
                startDate = LocalDate.now();
            }
        } else {
            startDate = LocalDate.now();
        }

        System.out.println("📆 Viewing rooms starting from: " + startDate);

        // --- 3. Fetch all rooms ---
        List<Room> allRooms = roomDao.getAllRooms();
        if (allRooms == null || allRooms.isEmpty()) {
            System.out.println("⚠️ No rooms found in database");
        } else {
            System.out.println("📊 Total rooms found: " + allRooms.size());
        }

        // --- 4. Set request attributes for JSP ---
        request.setAttribute("rooms", allRooms);
        request.setAttribute("today", LocalDate.now());
        request.setAttribute("startDate", startDate);

        // --- 5. Forward to JSP ---
        try {
            request.getRequestDispatcher("roomAvailability.jsp").forward(request, response);
            System.out.println("📤 Forwarded to roomAvailability.jsp");
        } catch (Exception e) {
            System.err.println("❌ Error forwarding to JSP: " + e.getMessage());
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Unable to load room availability");
        }
    }
}