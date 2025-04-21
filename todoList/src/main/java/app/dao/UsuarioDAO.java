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
        String query = "SELECT * FROM usuario WHERE email = ?";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(query)) {

            statement.setString(1, email);
            ResultSet resultSet = statement.executeQuery();

            if (resultSet.next()) {
                String hashedPassword = resultSet.getString("contrasena");
                if (org.mindrot.jbcrypt.BCrypt.checkpw(contrasena, hashedPassword)) {
                    usuario = new Usuario(
                            resultSet.getInt("id_usuario"),
                            resultSet.getString("nombre"),
                            resultSet.getString("email"),
                            hashedPassword
                    );
                }
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
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
}

