package itu.framework.model;

public class JsonResponse {
    private int status;
    private Object data;
    private String message;
    private String error;

    public JsonResponse() {
        this.status = 200;
    }

    public JsonResponse(Object data) {
        this.status = 200;
        this.data = data;
        this.message = "Success";
    }

    public JsonResponse(int status, Object data, String message) {
        this.status = status;
        this.data = data;
        this.message = message;
    }

    public static JsonResponse success(Object data) {
        return new JsonResponse(200, data, "Success");
    }

    public static JsonResponse success(Object data, String message) {
        return new JsonResponse(200, data, message);
    }

    public static JsonResponse error(int status, String error) {
        JsonResponse response = new JsonResponse();
        response.status = status;
        response.error = error;
        response.message = "Error";
        return response;
    }

    public static JsonResponse notFound(String message) {
        return error(404, message);
    }

    public static JsonResponse badRequest(String message) {
        return error(400, message);
    }

    public static JsonResponse serverError(String message) {
        return error(500, message);
    }

    public static JsonResponse unauthorized(String message) {
        return error(401, message);
    }

    public static JsonResponse forbidden(String message) {
        return error(403, message);
    }

    // Getters et Setters
    public int getStatus() {
        return status;
    }

    public void setStatus(int status) {
        this.status = status;
    }

    public Object getData() {
        return data;
    }

    public void setData(Object data) {
        this.data = data;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }
}
