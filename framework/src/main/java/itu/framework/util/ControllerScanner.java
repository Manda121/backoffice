package itu.framework.util;

import java.io.File;
import java.lang.reflect.Method;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import itu.framework.annotations.MyController;
import itu.framework.annotations.MyURL;
import jakarta.servlet.ServletContext;

public class ControllerScanner {

    public static Map<String, Map<String, Method>> scanControllers(ServletContext context) {
        Map<String, Map<String, Method>> urlMapping = new HashMap<>();

        try {
            String packagesToScan = context.getInitParameter("packagesToScan");

            if (packagesToScan != null && !packagesToScan.trim().isEmpty()) {
                // Scanner uniquement les packages spécifiés
                ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
                String[] packages = packagesToScan.split(",");
                for (String pkg : packages) {
                    pkg = pkg.trim();
                    scanPackage(pkg, classLoader, urlMapping);
                }
            } else {
                // Scanner tous les packages
                String classesPath = context.getRealPath("/WEB-INF/classes");
                if (classesPath != null) {
                    File classesDir = new File(classesPath);
                    if (classesDir.exists() && classesDir.isDirectory()) {
                        scanDirectory(classesDir, "", urlMapping);
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return urlMapping;
    }

    private static void scanPackage(String packageName, ClassLoader classLoader,
            Map<String, Map<String, Method>> urlMapping) {
        try {
            String path = packageName.replace('.', '/');
            URL resource = classLoader.getResource(path);

            if (resource != null) {
                File directory = new File(resource.getFile());
                if (directory.exists() && directory.isDirectory()) {
                    scanDirectory(directory, packageName, urlMapping);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void scanDirectory(File directory, String packageName, Map<String, Map<String, Method>> urlMapping) {
        File[] files = directory.listFiles();
        if (files == null)
            return;

        for (File file : files) {
            if (file.isDirectory()) {
                String newPackage = packageName.isEmpty() ? file.getName() : packageName + "." + file.getName();
                scanDirectory(file, newPackage, urlMapping);
            } else if (file.getName().endsWith(".class")) {
                String className = packageName + '.' + file.getName().substring(0, file.getName().length() - 6);
                try {
                    Class<?> clazz = Class.forName(className);
                    if (clazz.isAnnotationPresent(MyController.class)) {
                        Method[] methods = clazz.getDeclaredMethods();
                        for (Method method : methods) {
                            if (method.isAnnotationPresent(MyURL.class)) {
                                MyURL urlAnn = method.getAnnotation(MyURL.class);
                                String url = urlAnn.value();
                                String httpMethod = urlAnn.method().toUpperCase();

                                urlMapping.putIfAbsent(url, new HashMap<>());
                                urlMapping.get(url).put(httpMethod, method);
                            }
                        }
                    }
                } catch (Exception e) {
                    // Ignorer les classes non chargeables
                }
            }
        }
    }
}