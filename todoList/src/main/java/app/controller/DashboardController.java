package app.controller;

import app.DBConnection;
import app.dao.CategoriaDAO;
import app.dao.TaskDAO;
import app.model.Task;
import javafx.application.Platform;
import javafx.beans.binding.Bindings;
import javafx.beans.binding.BooleanBinding;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.collections.*;
import app.model.Usuario;
import javafx.stage.Stage;

import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;


public class DashboardController {
    final int MAX_LEN = 35;
    private int usuarioId;
    @FXML
    private Label welcomeLabel;

    private final TaskDAO taskDAO = new TaskDAO();

    private final CategoriaDAO categoriaDAO = new CategoriaDAO();

    private List<Task> todasLasTareas = new ArrayList<>();

    private Usuario usuario;

    @FXML
    private ComboBox<String> sectionComboBox;

    @FXML
    private Button deleteTaskButton;

    @FXML
    private Button addTaskButton;

    @FXML
    private Button logoutButton;

    @FXML
    private Button changeStatusButton;

    @FXML
    private TableView<Task> taskTable;
    @FXML
    private TableColumn<Task, String> taskColumn;
    @FXML
    private TableColumn<Task, String> statusColumn;
    @FXML
    private ComboBox<String> statusComboBox;

    @FXML
    private TextField taskField;
    @FXML
    private Button eliminarSeccionButton;

    private ObservableList<Task> tasks;

    public void setUsuarioId(int id) {
        this.usuarioId = id;
    }

    @FXML
    public void initialize() {
        tasks = FXCollections.observableArrayList();
        taskTable.setItems(tasks);

        taskColumn.setCellValueFactory(data -> data.getValue().taskProperty());
        statusColumn.setCellValueFactory(data -> data.getValue().statusProperty());

        sectionComboBox.getItems().clear();
        sectionComboBox.getItems().addAll(categoriaDAO.obtenerSecciones());

        if (!sectionComboBox.getItems().isEmpty()) {
            sectionComboBox.getSelectionModel().selectFirst();
        }

        statusComboBox.getItems().addAll("Pendiente", "En progreso", "Completado");
        statusComboBox.getSelectionModel().selectFirst();

        sectionComboBox.valueProperty().addListener((obs, oldVal, newVal) -> {
            filtrarTareasPorSeccion(newVal);
        });

        addTaskButton.disableProperty().bind(taskField.textProperty().isEmpty());

        changeStatusButton.disableProperty().bind(
                taskTable.getSelectionModel().selectedItemProperty().isNull()
        );

        deleteTaskButton.disableProperty().bind(
                taskTable.getSelectionModel().selectedItemProperty().isNull()
        );

        Platform.runLater(() -> {
            taskField.setTextFormatter(new TextFormatter<String>(change ->
                    change.getControlNewText().length() <= MAX_LEN ? change : null
            ));

            if (sectionComboBox.getItems().size() > 1) {
                String current = sectionComboBox.getValue();
                sectionComboBox.getSelectionModel().select(1);
                sectionComboBox.getSelectionModel().select(current);
            }
        });
    }

    @FXML
    public void filtrarTareasPorSeccion(String nuevaSeccion) {
        if (usuario != null && nuevaSeccion != null) {
            List<Task> tareasFiltradas = taskDAO.obtenerTareasPorSeccion(usuario.getId(), nuevaSeccion);
            tasks.setAll(tareasFiltradas);
        }
    }

    @FXML
    public void handleAddTask() {
        String tarea = taskField.getText().trim();
        String estado = statusComboBox.getValue();
        String nombreCategoria = sectionComboBox.getValue();

        if (!tarea.isEmpty()) {
            int categoriaId = categoriaDAO.obtenerIdOCrear(nombreCategoria);
            if (categoriaId != -1) {
                Task nuevaTarea = new Task(tarea, estado);
                taskDAO.guardarTarea(nuevaTarea, usuario.getId(), categoriaId);
                tasks.add(nuevaTarea);
                taskField.clear();
                tasks.setAll(taskDAO.obtenerTareasPorSeccion(usuario.getId(), nombreCategoria));
            } else {
                System.out.println("No se encontró la categoría en la base de datos.");
            }
        }
    }

    public void setUsuario(Usuario usuario) {
        if (usuario != null) {
            this.usuario = usuario;
            this.usuarioId = usuario.getId();
            welcomeLabel.setText("Bienvenido, " + usuario.getNombre() + "!");
            tasks.setAll(taskDAO.obtenerTareasPorUsuario(usuario.getId()));
            String primeraSeccion = sectionComboBox.getValue();
            filtrarTareasPorSeccion(primeraSeccion);
        } else {
            welcomeLabel.setText("Bienvenido!");
        }
    }


    @FXML
    public void handleAddSection() {
        TextInputDialog dialog = new TextInputDialog();
        dialog.setTitle("Agregar nueva sección");
        dialog.setHeaderText("Ingresa el nombre de la nueva sección");
        dialog.setContentText("Sección:");

        dialog.getEditor().setTextFormatter(new TextFormatter<>(change -> {
            if (change.getControlNewText().length() > MAX_LEN) {
                return null;
            }
            return change;
        }));

        dialog.showAndWait().ifPresent(nameInput -> {
            String name = nameInput.trim();

            if (name.isEmpty()) {
                showAlert("Error", "El nombre de la sección no puede estar vacío.", Alert.AlertType.WARNING);
                return;
            }

            if (sectionComboBox.getItems().contains(name)) {
                showAlert("Error", "La sección \"" + name + "\" ya existe.", Alert.AlertType.WARNING);
                return;
            }

            try {
                sectionComboBox.getItems().add(name);
                categoriaDAO.obtenerIdOCrear(name);
                showAlert("Éxito", "Sección \"" + name + "\" creada correctamente.", Alert.AlertType.INFORMATION);
            } catch (Exception e) {
                showAlert("Error", "No se pudo crear la sección. Quizá ya existe en la base de datos.", Alert.AlertType.ERROR);

            }
        });

    }

    @FXML
    public void handleChangeStatus() {
        Task tareaSeleccionada = taskTable.getSelectionModel().getSelectedItem();
        if (tareaSeleccionada != null) {
            String nuevoEstado = obtenerSiguienteEstado(tareaSeleccionada.getStatus());
            tareaSeleccionada.setStatus(nuevoEstado);

            try (Connection conn = DBConnection.getConnection()) {
                String sql = "UPDATE tarea SET estado = ? WHERE id_tarea = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setString(1, nuevoEstado);
                stmt.setInt(2, tareaSeleccionada.getId());
                stmt.executeUpdate();
            } catch (SQLException e) {
                e.printStackTrace();
            }

            taskTable.refresh();
        }
    }

    private String obtenerSiguienteEstado(String estadoActual) {
        switch (estadoActual) {
            case "Pendiente":
                return "En progreso";
            case "En progreso":
                return "Completado";
            case "Completado":
                return "Pendiente";
            default:
                return "Pendiente";
        }
    }

    @FXML
    public void handleDeleteTask() {
        Task selectedTask = taskTable.getSelectionModel().getSelectedItem();
        if (selectedTask != null) {
            taskDAO.eliminarTarea(selectedTask, usuario.getId());

            String seccionActual = sectionComboBox.getValue();
            filtrarTareasPorSeccion(seccionActual);
        }
    }

    @FXML
    private void handleEliminarSeccion() {
        String nombre = sectionComboBox.getValue();
        if (nombre == null || nombre.trim().isEmpty()) {
            showAlert("Error", "Selecciona una sección primero.", Alert.AlertType.WARNING);
            return;
        }

        int idCat = categoriaDAO.obtenerIdDeCategoria(nombre);
        if (idCat == -1) {
            showAlert("Error", "Sección no encontrada en la base de datos.", Alert.AlertType.ERROR);
            return;
        }

        if (categoriaDAO.esPorDefecto(idCat)) {
            showAlert("Error", "No se puede eliminar una sección por defecto.", Alert.AlertType.ERROR);
            return;
        }
        System.out.println(idCat);
        if (categoriaDAO.tieneTareasIncompletas(idCat)) {
            showAlert("Error", "No se puede eliminar la sección porque tiene tareas pendientes o en progreso.", Alert.AlertType.ERROR);
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            try (PreparedStatement delT = conn.prepareStatement("DELETE FROM tarea WHERE categoria_id = ?")) {
                delT.setInt(1, idCat);
                delT.executeUpdate();
            }

            try (PreparedStatement delC = conn.prepareStatement("DELETE FROM categorias WHERE id_categoria = ?")) {
                delC.setInt(1, idCat);
                delC.executeUpdate();
            }

            sectionComboBox.getItems().remove(nombre);
            sectionComboBox.setValue(null);
            taskTable.getItems().clear();
            showAlert("Éxito", "Sección eliminada correctamente.", Alert.AlertType.INFORMATION);

        } catch (SQLException e) {
            showAlert("Error", "Ocurrió un error al eliminar la sección.", Alert.AlertType.ERROR);
            e.printStackTrace();
        }
    }


    @FXML
    private void handleLogout() {
        usuario = null;

        try {

            FXMLLoader loader = new FXMLLoader(getClass().getResource("/view/login.fxml"));
            Parent root = loader.load();


            LoginController loginController = loader.getController();

            Scene loginScene = new Scene(root);
            Stage currentStage = (Stage) logoutButton.getScene().getWindow();
            currentStage.setScene(loginScene);
            currentStage.show();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void showAlert(String title, String content, Alert.AlertType type) {
        Alert alert = new Alert(type);
        alert.setTitle(title);
        alert.setHeaderText(null);
        alert.setContentText(content);
        alert.showAndWait();
    }

    @FXML
    private void verTareasPorEstado(ActionEvent event) {
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/view/status-view.fxml"));
            Parent root = loader.load();

            StatusController controller = loader.getController();
            controller.setUsuarioId(usuarioId);

            Stage stage = new Stage();
            stage.setTitle("Tareas por Estado");
            stage.setScene(new Scene(root));
            stage.show();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
