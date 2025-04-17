// Archivo: CategoriaDAO.java

package app.dao;

import app.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CategoriaDAO {

    public int obtenerIdOCrear(String nombreCategoria) {
        int id = obtenerIdDeCategoria(nombreCategoria);
        if (id != -1) return id;

        // Si no existe, la insertamos
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "INSERT INTO categorias (nombre) VALUES (?)";
            PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            stmt.setString(1, nombreCategoria);
            stmt.executeUpdate();

            ResultSet rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return -1;
    }
    public int obtenerIdDeCategoria(String nombreCategoria) {
        int id = -1;
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "SELECT id_categoria FROM categorias WHERE nombre = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, nombreCategoria);

            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                id = rs.getInt("id_categoria");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return id;
    }

    public List<String> obtenerSecciones() {
        List<String> secciones = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "SELECT nombre FROM categorias";
            PreparedStatement stmt = conn.prepareStatement(sql);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                secciones.add(rs.getString("nombre"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return secciones;
    }


    public void agregarCategoria(String nombreCategoria) {
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "INSERT INTO categorias (nombre) VALUES (?)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, nombreCategoria);
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }


}

