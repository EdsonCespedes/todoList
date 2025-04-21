package app.dao;

import app.model.Label;
import java.util.*;

public class LabelDAO {
    public List<Label> getAllLabels() {
        return List.of(new Label(1, "Urgente"), new Label(2, "Importante"));
    }
}
