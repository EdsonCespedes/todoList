package app.controller;

import javafx.fxml.FXML;
import javafx.scene.control.TextField;
import javafx.scene.control.PasswordField;
import javafx.scene.control.Label;

import jakarta.mail.*;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.util.Properties;
import java.util.regex.Pattern;


public class RegisterController {

    @FXML
    private TextField emailField;

    @FXML
    private PasswordField passwordField;

    @FXML
    private PasswordField confirmPasswordField;

    @FXML
    private Label statusLabel;

    @FXML
    public void handleRegister() {
        String email = emailField.getText().trim();
        String password = passwordField.getText();
        String confirmPassword = confirmPasswordField.getText();

        if (!isValidEmail(email)) {
            statusLabel.setText("Correo inválido.");
            return;
        }

        if (!isValidPassword(password)) {
            statusLabel.setText("La contraseña debe tener al menos 1 mayúscula, 1 minúscula y 1 número.");
            return;
        }

        if (!password.equals(confirmPassword)) {
            statusLabel.setText("Las contraseñas no coinciden.");
            return;
        }

        if (!sendEmailConfirmation(email)) {
            statusLabel.setText("No se pudo enviar el correo. Registro cancelado.");
            return;
        }

        statusLabel.setText("¡Registro exitoso!");
        // Aquí se puede guardar en la base de datos
    }

    private boolean isValidEmail(String email) {
        return Pattern.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$", email);
    }

    private boolean isValidPassword(String password) {
        return Pattern.matches("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).+$", password);
    }

    private boolean sendEmailConfirmation(String to) {
        final String from = "fruukz@gmail.com";
        final String pass = "xkmydqafyivqbwmz";

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");

        Session session = Session.getInstance(props, new Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(from, pass);
            }
        });
        session.setDebug(true);

        try {
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(from));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSubject("¡Registro exitoso!");
            message.setText("Hola, gracias por registrarte en la app To-Do List.");

            Transport.send(message);
            return true;
        } catch (MessagingException e) {
            e.printStackTrace();
            return false;
        }
    }
}
