package app.model;

public class Category {
    private int id;
    private String nombre;
    private boolean porDefecto;

    public Category() {}

    public Category(int id, String nombre, boolean porDefecto) {
        this.id = id;
        this.nombre = nombre;
        this.porDefecto  = porDefecto;
    }

    public int getId() { return id; }

    public void setId(int id) { this.id = id; }

    public String getNombre() { return nombre; }

    public void setNombre(String nombre) { this.nombre = nombre; }

    public boolean isPorDefecto() { return porDefecto; }

    public void setPorDefecto(boolean porDefecto) { this.porDefecto = porDefecto; }
}
