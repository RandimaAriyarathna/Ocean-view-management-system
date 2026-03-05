package com.oceanview.controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.oceanview.dao.ReservationDao;

@WebServlet("/delete-reservation")
public class DeleteReservationServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String reservationNumber = request.getParameter("number");

        try {
            ReservationDao dao = new ReservationDao();

            boolean deleted = dao.deleteReservation(reservationNumber);

            if (deleted) {

                response.sendRedirect(
                    "view-reservations?type=success&message=Reservation+" 
                    + reservationNumber + "+deleted+successfully"
                );

            } else {

                response.sendRedirect(
                    "view-reservations?type=error&message=Delete+failed"
                );
            }

        } catch (Exception e) {
            e.printStackTrace();

            response.sendRedirect(
                "view-reservations?type=error&message=System+error+during+delete"
            );
        }
    }
}
