// Archivo: CategoriaDAO.java

package app.dao;

import app.DBConnection;
import app.model.Category;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CategoriaDAO {

    public int obtenerIdOCrear(String nombreCategoria, int usuarioId) {
        int id = obtenerIdDeCategoria(nombreCategoria);
        if (id != -1) return id;

        try (Connection conn = DBConnection.getConnection()) {
            String sql = "INSERT INTO categorias (nombre, por_defecto, usuario_id) VALUES (?, 0, ?)";
            PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            stmt.setString(1, nombreCategoria);
            stmt.setInt(2, usuarioId);
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
        String sql = "SELECT id_categoria FROM categorias WHERE nombre = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, nombreCategoria);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    id = rs.getInt("id_categoria");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return id;
    }

    public List<String> obtenerSecciones(int usuarioId) {
        List<String> secciones = new ArrayList<>();

        // Llamar al procedimiento almacenado en lugar de la consulta directa
        String sql = "{CALL sp_list_categories(?)}"; // Procedimiento almacenado

        try (Connection conn = DBConnection.getConnection();
             CallableStatement stmt = conn.prepareCall(sql)) {

            stmt.setInt(1, usuarioId);
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
            String sql = "{CALL sp_create_category(?)}";
            CallableStatement stmt = conn.prepareCall(sql);
            stmt.setString(1, nombreCategoria);
            stmt.execute();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public boolean esPorDefecto(int idCategoria) {
        String sql = "SELECT por_defecto FROM categorias WHERE id_categoria = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql))
        {
            stmt.setInt(1, idCategoria);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getBoolean("por_defecto");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean tieneTareasIncompletas(int idCategoria) {
        String sql = "SELECT COUNT(*) AS cnt FROM tarea WHERE categoria_id = ? AND estado <> 'Completado'";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, idCategoria);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("cnt") > 0;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return true;
    }
}