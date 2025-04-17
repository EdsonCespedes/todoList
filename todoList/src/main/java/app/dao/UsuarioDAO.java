package app.dao;

import app.DBConnection;
import app.model.Usuario;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class UsuarioDAO {

    public Usuario validarUsuario(String email, String contrasena) {
        Usuario usuario = null;
        String query = "SELECT * FROM usuario WHERE email = ? AND contrasena = ?";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setString(1, email);
            statement.setString(2, contrasena);

            ResultSet resultSet = statement.executeQuery();
            if (resultSet.next()) {
                // Asegúrate de incluir 'nombre' aquí
                usuario = new Usuario(resultSet.getInt("id_usuario"), resultSet.getString("nombre"), resultSet.getString("email"), resultSet.getString("contrasena"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return usuario;
    }


    public boolean existeUsuario(String email) {
        String sql = "SELECT COUNT(*) FROM usuario WHERE email = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, email);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0; // Si el conteo es mayor a 0, el usuario existe
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }


}

