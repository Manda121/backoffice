package itu.framework.model;
import java.util.HashMap;
public class ModelView {
    private String view;
    private HashMap<String, Object> data;

    public ModelView() {
    }

    public ModelView(String view) {
        this.view = view;
        this.data = new HashMap<>();
    }

    public String getView() {
        return view;
    }

    public void setView(String view) {
        this.view = view;
    }

    public HashMap<String, Object> getData() {
        return this.data;
    }

    public void setData(HashMap<String, Object> data) {
        this.data = data;
    }

    public void addItem(String key, Object value) {
        this.data.put(key, value);
    }

    public Object getItem(String key) {
        return this.data.get(key);
    }

    public void removeItem(String key) {
        this.data.remove(key);
    }
}
