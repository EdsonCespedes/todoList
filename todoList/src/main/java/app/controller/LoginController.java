package app.controller;

import app.dao.UsuarioDAO;
import app.model.Usuario;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.stage.Stage;

import java.io.IOException;

public class LoginController {

    @FXML
    private TextField emailField;

    @FXML
    private PasswordField contrasenaField;

    @FXML
    private Label statusLabel;

    @FXML
    private Button loginButton;

    @FXML
    public void handleLogin() {
        String email = emailField.getText().trim();
        String contrasena = contrasenaField.getText();

        UsuarioDAO usuarioDAO = new UsuarioDAO();
        Usuario usuario = usuarioDAO.validarUsuario(email, contrasena);

        if (usuario != null) {
            try {
                FXMLLoader loader = new FXMLLoader(getClass().getResource("/view/Dashboard.fxml"));
                Parent root = loader.load();

                // Pasar el usuario al Dashboard
                DashboardController controller = loader.getController();
                controller.setUsuario(usuario);

                Stage stage = (Stage) loginButton.getScene().getWindow();
                stage.setScene(new Scene(root));
                stage.setTitle("Dashboard");
                stage.show();
            } catch (IOException e) {
                e.printStackTrace();
            }
        } else {
            // Mostrar un mensaje de error si las credenciales son incorrectas
            showAlert("Error", "Credenciales incorrectas", Alert.AlertType.ERROR);
        }
    }

    @FXML
    public void goToRegister() {
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/view/register.fxml"));
            Stage stage = (Stage) emailField.getScene().getWindow();
            stage.setScene(new Scene(loader.load()));
            stage.setTitle("Registro");
            stage.show();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void showAlert(String title, String message, Alert.AlertType alertType) {
        Alert alert = new Alert(alertType);
        alert.setTitle(title);
        alert.setHeaderText(null);
        alert.setContentText(message);
        alert.showAndWait();
    }
}

