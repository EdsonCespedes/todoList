package app.controller;

import app.DBConnection;
import app.model.Task;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.collections.*;
import app.dao.CategoriaDAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class TaskController {
    @FXML private TableView<Task> taskTable;
    @FXML private TableColumn<Task, String> taskColumn;
    @FXML private TableColumn<Task, String> statusColumn;
    @FXML private ComboBox<String> statusComboBox;
    @FXML private ComboBox<String> sectionComboBox;
    @FXML private TextField taskField;

    private ObservableList<Task> tasks;

    CategoriaDAO categoriaDAO = new CategoriaDAO();

    @FXML
    public void initialize() {
        tasks = FXCollections.observableArrayList();
        taskTable.setItems(tasks);

        taskColumn.setCellValueFactory(data -> data.getValue().taskProperty());
        statusColumn.setCellValueFactory(data -> data.getValue().statusProperty());

        statusComboBox.getItems().clear();
        statusComboBox.getItems().addAll("Pendiente", "En progreso", "Completad0");
        statusComboBox.getSelectionModel().selectFirst();

        // Cargar las secciones desde la base de datos
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
        }
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
