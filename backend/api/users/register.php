<?php
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if(
    !empty($data->email) &&
    !empty($data->password) &&
    !empty($data->displayName)
){
    // Check if email exists
    $check_query = "SELECT uid FROM users WHERE email = :email LIMIT 0,1";
    $check_stmt = $db->prepare($check_query);
    $check_stmt->bindParam(':email', $data->email);
    $check_stmt->execute();
    
    if($check_stmt->rowCount() > 0){
        http_response_code(400);
        echo json_encode(array("message" => "Email already exists."));
        exit();
    }

    $query = "INSERT INTO users
            SET
                uid = :uid,
                email = :email,
                password = :password,
                displayName = :displayName,
                createdAt = :createdAt,
                lastActive = :lastActive,
                isAdmin = 0";

    $stmt = $db->prepare($query);

    // Generate UUID
    $uid = uniqid('user_', true);
    
    // Hash password
    $password_hash = password_hash($data->password, PASSWORD_BCRYPT);
    
    $now = round(microtime(true) * 1000); // Milliseconds

    $stmt->bindParam(":uid", $uid);
    $stmt->bindParam(":email", $data->email);
    $stmt->bindParam(":password", $password_hash);
    $stmt->bindParam(":displayName", $data->displayName);
    $stmt->bindParam(":createdAt", $now);
    $stmt->bindParam(":lastActive", $now);

    if($stmt->execute()){
        http_response_code(201);
        echo json_encode(array(
            "message" => "User was created.",
            "uid" => $uid,
            "email" => $data->email,
            "displayName" => $data->displayName
        ));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create user."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data."));
}
?>
