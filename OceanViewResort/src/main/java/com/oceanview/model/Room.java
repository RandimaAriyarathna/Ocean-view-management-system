package com.oceanview.model;

public class Room {
    private String roomNumber;
    private String roomType;
    private String status; // AVAILABLE, OCCUPIED, MAINTENANCE, CLEANING
    private int floor;
    private String features;
    private double rate;
    
    // Constructors
    public Room() {}
    
    public Room(String roomNumber, String roomType, String status, int floor, double rate) {
        this.roomNumber = roomNumber;
        this.roomType = roomType;
        this.status = status;
        this.floor = floor;
        this.rate = rate;
    }
    
    // Getters and Setters
    public String getRoomNumber() { return roomNumber; }
    public void setRoomNumber(String roomNumber) { this.roomNumber = roomNumber; }
    
    public String getRoomType() { return roomType; }
    public void setRoomType(String roomType) { this.roomType = roomType; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public int getFloor() { return floor; }
    public void setFloor(int floor) { this.floor = floor; }
    
    public String getFeatures() { return features; }
    public void setFeatures(String features) { this.features = features; }
    
    public double getRate() { return rate; }
    public void setRate(double rate) { this.rate = rate; }
}