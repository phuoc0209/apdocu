<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Target directory
$target_dir = "../../uploads/";
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
}

if(isset($_FILES['image'])){
    $file_name = $_FILES['image']['name'];
    $file_tmp = $_FILES['image']['tmp_name'];
    $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));
    
    $extensions = array("jpeg", "jpg", "png", "gif");
    
    if(in_array($file_ext, $extensions) === false){
        http_response_code(400);
        echo json_encode(array("message" => "Extension not allowed, please choose a JPEG or PNG file."));
        exit();
    }
    
    $new_file_name = uniqid() . '.' . $file_ext;
    $target_file = $target_dir . $new_file_name;
    
    if(move_uploaded_file($file_tmp, $target_file)){
        // Return the URL to the file
        // Assuming the API is at http://localhost/appdocu1/api/
        // The file is at http://localhost/appdocu1/uploads/
        // We need to construct the full URL. For now, we return a relative path or assume a base URL.
        // Let's return the filename and let the client construct the URL or return a full URL if we knew the host.
        
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
        $host = $_SERVER['HTTP_HOST'];
        // Assuming script is in /api/upload.php and we want /uploads/file.jpg
        // We need to know the project root path relative to document root.
        // Simple hack: return the path relative to the server root if possible, or just the filename.
        
        // Let's assume the app knows the base URL.
        echo json_encode(array(
            "message" => "Success",
            "fileName" => $new_file_name
        ));
    } else {
        http_response_code(500);
        echo json_encode(array("message" => "Failed to upload file."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "No file uploaded."));
}
?>
