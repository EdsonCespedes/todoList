package app.controller;

import app.dao.TaskDAO;
import app.model.Task;
import javafx.fxml.FXML;
import javafx.scene.control.ListView;

import java.util.List;
import java.util.stream.Collectors;

public class StatusController {

    @FXML
    private ListView<String> listCompletado;
    @FXML
    private ListView<String> listEnProgreso;
    @FXML
    private ListView<String> listPendiente;

    private final TaskDAO taskDAO = new TaskDAO();
    private int usuarioId;

    public void setUsuarioId(int usuarioId) {
        this.usuarioId = usuarioId;
        cargarTareasPorEstado();
    }

    private void cargarTareasPorEstado() {
        List<Task> tareas = taskDAO.obtenerTareasPorUsuario(usuarioId);

        listCompletado.getItems().setAll(tareas.stream()
                .filter(t -> t.getStatus().equalsIgnoreCase("Completado"))
                .map(Task::getTask)
                .collect(Collectors.toList()));

        listEnProgreso.getItems().setAll(tareas.stream()
                .filter(t -> t.getStatus().equalsIgnoreCase("En progreso"))
                .map(Task::getTask)
                .collect(Collectors.toList()));

        listPendiente.getItems().setAll(tareas.stream()
                .filter(t -> t.getStatus().equalsIgnoreCase("Pendiente"))
                .map(Task::getTask)
                .collect(Collectors.toList()));
    }
}