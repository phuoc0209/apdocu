<?php
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if(
    !empty($data->title) &&
    !empty($data->ownerId)
){
    $query = "INSERT INTO products
            SET
                id = :id,
                title = :title,
                description = :description,
                imageUrls = :imageUrls,
                category = :category,
                product_condition = :condition,
                status = :status,
                ownerId = :ownerId,
                ownerName = :ownerName,
                ownerPhotoURL = :ownerPhotoURL,
                location_lat = :location_lat,
                location_lng = :location_lng,
                locationAddress = :locationAddress,
                createdAt = :createdAt,
                updatedAt = :updatedAt,
                viewCount = 0,
                tags = :tags";

    $stmt = $db->prepare($query);

    // Generate UUID
    $id = uniqid('prod_', true);
    
    $now = round(microtime(true) * 1000);

    // Sanitize and bind
    $stmt->bindParam(":id", $id);
    $stmt->bindParam(":title", $data->title);
    $stmt->bindParam(":description", $data->description);
    
    $imageUrlsJson = json_encode($data->imageUrls);
    $stmt->bindParam(":imageUrls", $imageUrlsJson);
    
    $stmt->bindParam(":category", $data->category);
    $stmt->bindParam(":condition", $data->condition);
    $stmt->bindParam(":status", $data->status);
    $stmt->bindParam(":ownerId", $data->ownerId);
    $stmt->bindParam(":ownerName", $data->ownerName);
    $stmt->bindParam(":ownerPhotoURL", $data->ownerPhotoURL);
    
    $lat = isset($data->location->latitude) ? $data->location->latitude : null;
    $lng = isset($data->location->longitude) ? $data->location->longitude : null;
    $stmt->bindParam(":location_lat", $lat);
    $stmt->bindParam(":location_lng", $lng);
    
    $stmt->bindParam(":locationAddress", $data->locationAddress);
    $stmt->bindParam(":createdAt", $now);
    $stmt->bindParam(":updatedAt", $now);
    
    $tagsJson = json_encode($data->tags);
    $stmt->bindParam(":tags", $tagsJson);

    if($stmt->execute()){
        http_response_code(201);
        echo json_encode(array("message" => "Product was created.", "id" => $id));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create product."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data."));
}
?>
