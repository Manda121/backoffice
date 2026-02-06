package controller;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import itu.framework.annotations.MyController;
import itu.framework.annotations.MyURL;
import itu.framework.model.JsonResponse;
import itu.framework.model.ModelView;
import models.Departement;
import models.Employe;

@MyController(value = "Test")
public class ControllerTest {

    @MyURL(value = "/admin", method = "GET")
    public ModelView showAdmin() {
        return new ModelView("admin/dashboard.jsp");
    }

    @MyURL(value = "/departement/{id}/{b}", method = "GET")
    public ModelView getDepartementById(Integer id, String b) {
        ModelView mv = new ModelView("departement.jsp");
        mv.addItem("id", id);
        mv.addItem("b", b);
        return mv;
    }

    @MyURL(value = "/form", method = "GET")
    public ModelView showForm() {
        return new ModelView("form.jsp");
    }

    @MyURL(value = "/form", method = "POST")
    public ModelView submitForm(HashMap<String, Object> params) {
        ModelView mv = new ModelView("form-result.jsp");
        mv.addItem("name", params.get("name"));
        mv.addItem("age", params.get("age"));
        return mv;
    }

    @MyURL(value = "/form/employe", method = "GET")
    public ModelView showFormEmploye() {
        return new ModelView("employeForm.jsp");
    }

    @MyURL(value = "/employe", method = "POST")
    public ModelView submitFormEmploye(Employe e) {
        ModelView mv = new ModelView("employe.jsp");
        mv.addItem("employe", e);
        return mv;
    }

    @MyURL(value = "/api/employe", method = "POST")
    public JsonResponse submitFormEmployeJson(Employe e) {
        if (e == null || e.getNom() == null || e.getNom().isEmpty()) {
            return JsonResponse.badRequest("Le nom de l'employé est requis");
        }
        return JsonResponse.success(e, "Employé créé avec succès");
    }

    @MyURL(value = "/upload", method = "GET")
    public ModelView showFormUpload() {
        return new ModelView("upload.jsp");
    }

    @MyURL(value = "/upload", method = "POST")
    public ModelView handleUpload(Map<String, byte[]> files) {
        ModelView mv = new ModelView("upload-result.jsp");
        mv.addItem("nbFiles", files != null ? files.size() : 0);
        return mv;
    }

}
