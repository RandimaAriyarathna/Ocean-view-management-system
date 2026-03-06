package com.oceanview.service;

public class ServiceResult<T> {
    private boolean success;
    private String message;
    private T data;

    // Constructor
    private ServiceResult(boolean success, T data, String message) {
        this.success = success;
        this.data = data;
        this.message = message;
    }

    public static <T> ServiceResult<T> success(T data, String message) {
        return new ServiceResult<>(true, data, message);
    }

    public static <T> ServiceResult<T> error(String message) {
        return new ServiceResult<>(false, null, message);
    }

    // Getters
    public boolean isSuccess() { return success; }
    public String getMessage() { return message; }
    public T getData() { return data; }
}