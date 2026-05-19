<?php
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->email) && !empty($data->password)){
    $query = "SELECT * FROM users WHERE email = :email LIMIT 0,1";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $data->email);
    $stmt->execute();

    if($stmt->rowCount() > 0){
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if(password_verify($data->password, $row['password'])){
            // Update lastActive
            $update_query = "UPDATE users SET lastActive = :lastActive WHERE uid = :uid";
            $update_stmt = $db->prepare($update_query);
            $now = round(microtime(true) * 1000);
            $update_stmt->bindParam(':lastActive', $now);
            $update_stmt->bindParam(':uid', $row['uid']);
            $update_stmt->execute();

            // Remove password from response
            unset($row['password']);
            
            http_response_code(200);
            echo json_encode($row);
        } else {
            http_response_code(401);
            echo json_encode(array("message" => "Invalid password."));
        }
    } else {
        http_response_code(404);
        echo json_encode(array("message" => "User not found."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data."));
}
?>
