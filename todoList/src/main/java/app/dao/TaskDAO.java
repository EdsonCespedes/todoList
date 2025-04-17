package app.dao;

import app.DBConnection;
import app.model.Task;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TaskDAO {

    public void guardarTarea(Task task, int usuarioId, int categoriaId) {
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "INSERT INTO tarea (usuario_id, titulo, estado, categoria_id) VALUES (?, ?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            stmt.setString(2, task.getTask());
            stmt.setString(3, task.getStatus());
            stmt.setInt(4, categoriaId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public List<Task> obtenerTareasPorUsuario(int usuarioId) {
        List<Task> tareas = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "SELECT titulo, estado FROM tarea WHERE usuario_id = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                tareas.add(new Task(rs.getString("titulo"), rs.getString("estado")));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return tareas;
    }

    public void eliminarTarea(Task task, int usuarioId) {
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "DELETE FROM tarea WHERE usuario_id = ? AND titulo = ? AND estado = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            stmt.setString(2, task.getTask());
            stmt.setString(3, task.getStatus());
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void actualizarEstado(Task task, String nuevoEstado, int usuarioId) {
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "UPDATE tarea SET estado = ? WHERE usuario_id = ? AND titulo = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, nuevoEstado);
            stmt.setInt(2, usuarioId);
            stmt.setString(3, task.getTask());
            stmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public List<Task> obtenerTareasPorSeccion(int usuarioId, String nombreCategoria) {
        List<Task> tareas = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            String sql = """
                SELECT t.id_tarea, t.titulo, t.estado
                FROM tarea t
                JOIN categorias c ON t.categoria_id = c.id_categoria
                WHERE t.usuario_id = ? AND c.nombre = ?
                """;

            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            stmt.setString(2, nombreCategoria);

            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                int id = rs.getInt("id_tarea");
                String titulo = rs.getString("titulo");
                String estado = rs.getString("estado");
                tareas.add(new Task(id, titulo, estado, nombreCategoria)); // asegúrate de que Task tenga un constructor así
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return tareas;
    }


}
