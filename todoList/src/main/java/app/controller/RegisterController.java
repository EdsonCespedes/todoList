package app.controller;

import app.DBConnection;
import app.dao.UsuarioDAO;
import jakarta.mail.MessagingException;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.stage.Stage;
import javafx.scene.Parent;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class RegisterController {

    @FXML
    private TextField emailField;

    @FXML
    private PasswordField contrasenaField;

    @FXML
    private PasswordField confirmarContrasenaField;

    @FXML
    private Label statusLabel;

    @FXML
    private TextField nombreField;

    @FXML
    public void handleRegister() {
        String nombre = nombreField.getText().trim();
        String email = emailField.getText().trim();
        String contrasena = contrasenaField.getText();
        String confirmarContrasena = confirmarContrasenaField.getText();

        UsuarioDAO usuarioDAO = new UsuarioDAO();

        if (!email.matches("^[\\w.-]+@[\\w.-]+\\.\\w+$")) {
            statusLabel.setText("Correo inválido.");
            return;
        }

        if (!contrasena.matches("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).+$")) {
            statusLabel.setText("Contraseña débil. Usa mayúsculas, minúsculas y números.");
            return;
        }

        if (!contrasena.equals(confirmarContrasena)) {
            statusLabel.setText("Las contraseñas no coinciden.");
            return;
        }

        if (usuarioDAO.existeUsuario(email)) {
            statusLabel.setText("Correo ya registrado.");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            PreparedStatement stmt = conn.prepareStatement(
                    "INSERT INTO usuario (nombre, email, contrasena) VALUES (?, ?, ?)"
            );
            stmt.setString(1, nombre);
            stmt.setString(2, email);
            String hashedPassword = org.mindrot.jbcrypt.BCrypt
                    .hashpw(contrasena, org.mindrot.jbcrypt.BCrypt.gensalt());
            stmt.setString(3, hashedPassword);
            stmt.executeUpdate();

            try {
                // Enviar el correo
                app.util.MailService.enviarCorreoBienvenida(email, nombre);

                // Confirmar solo si se envió el correo
                conn.commit();
                statusLabel.setText("Registro exitoso. Redirigiendo...");

                FXMLLoader loader = new FXMLLoader(getClass().getResource("/view/login.fxml"));
                Stage stage = (Stage) emailField.getScene().getWindow();
                stage.setScene(new Scene(loader.load()));
            } catch (MessagingException mex) {
                conn.rollback();
                statusLabel.setText("No se pudo enviar el correo de bienvenida. Inténtalo más tarde.");
                mex.printStackTrace();
            }

        } catch (SQLException | IOException e) {
            statusLabel.setText("Error al registrar el usuario.");
            e.printStackTrace();
        }
    }



    @FXML
    public void goToLogin() {
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/view/Login.fxml"));
            Parent root = loader.load();
            Stage stage = (Stage) emailField.getScene().getWindow();
            stage.setScene(new Scene(root));
            stage.setTitle("Login");
            stage.show();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

