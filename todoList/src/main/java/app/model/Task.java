package app.model;

import javafx.beans.property.SimpleStringProperty;
import javafx.beans.property.StringProperty;

public class Task {
    private final int id;
    private final String section;
    private final StringProperty task = new SimpleStringProperty();
    private final StringProperty status = new SimpleStringProperty();

    public Task(int id, String task, String status, String section) {
        this.id = id;
        this.section = section;
        this.task.set(task);
        this.status.set(status);
    }

    public Task(String task, String status) {
        this(-1, task, status, null);
    }

    // Getter del id
    public int getId() {
        return id;
    }

    public String getTask() {
        return task.get();
    }

    public StringProperty taskProperty() {
        return task;
    }

    public String getStatus() {
        return status.get();
    }

    public void setStatus(String status) {
        this.status.set(status);
    }

    public StringProperty statusProperty() {
        return status;
    }
}


