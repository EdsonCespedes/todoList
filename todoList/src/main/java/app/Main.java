package app;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {

    @Override
    public void start(Stage primaryStage) throws Exception {
        FXMLLoader fxmlLoader = new FXMLLoader(getClass().getResource("/view/login.fxml"));
        Scene scene = new Scene(fxmlLoader.load());
        primaryStage.setScene(scene);
        primaryStage.setTitle("TodoList");
        primaryStage.getIcons().add(new javafx.scene.image.Image(getClass().getResourceAsStream("/ico.png")));
        primaryStage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}
