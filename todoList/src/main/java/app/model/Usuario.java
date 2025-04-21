package app.model;

import javafx.beans.property.*;

public class Usuario {
    private final IntegerProperty id = new SimpleIntegerProperty();
    private final StringProperty nombre = new SimpleStringProperty();
    private final StringProperty email = new SimpleStringProperty();
    private final StringProperty password = new SimpleStringProperty();

    public Usuario() {
    }

    public Usuario(int id, String nombre, String email, String password) {
        this.id.set(id);
        this.nombre.set(nombre);
        this.email.set(email);
        this.password.set(password);
    }

    public int getId() {
        return id.get();
    }

    public void setId(int id) {
        this.id.set(id);
    }

    public String getNombre() {
        return nombre.get();
    }

    public void setNombre(String nombre) {
        this.nombre.set(nombre);
    }
}
