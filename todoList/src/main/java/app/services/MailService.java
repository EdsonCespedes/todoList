package app.services;

import jakarta.mail.*;
import jakarta.mail.internet.*;

import java.util.Properties;

public class MailService {

    private final static String FROM_EMAIL = "fruukz@gmail.com";
    private final static String FROM_PASSWORD = "xkmydqafyivqbwmz";

    /**
     * Envía un correo de bienvenida personalizado.
     * @param destinatario email del nuevo usuario
     * @param nombreUsuario nombre del nuevo usuario
     * @throws MessagingException si falla el envío SMTP
     */
    public static void enviarCorreoBienvenida(String destinatario, String nombreUsuario) throws MessagingException {
        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");

        Session session = Session.getInstance(props, new Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(FROM_EMAIL, FROM_PASSWORD);
            }
        });

        Message message = new MimeMessage(session);
        message.setFrom(new InternetAddress(FROM_EMAIL));
        message.setRecipients(
                Message.RecipientType.TO,
                InternetAddress.parse(destinatario)
        );
        message.setSubject("¡Bienvenido, " + nombreUsuario + "!");
        message.setText(
                "Hola " + nombreUsuario + ",\n\n" +
                        "¡Tu cuenta ha sido registrada exitosamente en To-Do List!\n" +
                        "Ya puedes comenzar a crear tus tareas y secciones.\n\n" +
                        "¡Gracias por unirte!\n" +
                        "El equipo de To-Do List."
        );

        Transport.send(message);
    }
}