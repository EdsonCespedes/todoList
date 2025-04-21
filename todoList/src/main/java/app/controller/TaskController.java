package app.controller;

import app.model.Task;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.collections.*;
import app.dao.CategoriaDAO;

public class TaskController {
    @FXML private TableView<Task> taskTable;
    @FXML private TableColumn<Task, String> taskColumn;
    @FXML private TableColumn<Task, String> statusColumn;
    @FXML private ComboBox<String> statusComboBox;
    @FXML private ComboBox<String> sectionComboBox;
    @FXML private TextField taskField;
    final int MAX_LEN = 255;

    private ObservableList<Task> tasks;

    CategoriaDAO categoriaDAO = new CategoriaDAO();

    @FXML
    public void initialize() {
        tasks = FXCollections.observableArrayList();
        taskTable.setItems(tasks);
        taskField.setTextFormatter(new TextFormatter<String>(change ->
                change.getControlNewText().length() <= MAX_LEN ? change : null
        ));
        taskColumn.setCellValueFactory(data -> data.getValue().taskProperty());
        statusColumn.setCellValueFactory(data -> data.getValue().statusProperty());

        statusComboBox.getItems().clear();
        statusComboBox.getItems().addAll("Pendiente", "En Progreso", "Completado");
        statusComboBox.getSelectionModel().selectFirst();

        sectionComboBox.getItems().clear();
        sectionComboBox.getItems().addAll(categoriaDAO.obtenerSecciones());
        sectionComboBox.getSelectionModel().selectFirst();
    }


    @FXML
    public void handleAddTask() {
        String tarea = taskField.getText().trim();
        String estado = statusComboBox.getValue();

        if (!tarea.isEmpty()) {
            tasks.add(new Task(tarea, estado));
            taskField.clear();
        } else {
            showAlert("Error", "El nombre de la tarea no puede estar vacío.", Alert.AlertType.WARNING);
        }
    }

    private void showAlert(String error, String s, Alert.AlertType alertType) {
    }

    @FXML
    public void handleAddSection() {
        TextInputDialog dialog = new TextInputDialog();
        dialog.setTitle("Agregar nueva sección");
        dialog.setHeaderText("Ingresa el nombre de la nueva sección");
        dialog.setContentText("Sección:");

        dialog.showAndWait().ifPresent(name -> {
            if (!name.trim().isEmpty() && !sectionComboBox.getItems().contains(name)) {
                sectionComboBox.getItems().add(name.trim());
                // Guardar la nueva sección en la base de datos
                categoriaDAO.agregarCategoria(name.trim());
            }
        });
    }
}
