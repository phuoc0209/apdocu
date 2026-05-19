<?php
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$query = "SELECT * FROM products ORDER BY createdAt DESC";
$stmt = $db->prepare($query);
$stmt->execute();

$num = $stmt->rowCount();

if($num > 0){
    $products_arr = array();
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)){
        extract($row);
        
        $product_item = array(
            "id" => $id,
            "title" => $title,
            "description" => $description,
            "imageUrls" => json_decode($imageUrls),
            "category" => $category,
            "condition" => $product_condition, // Mapped from product_condition column
            "status" => $status,
            "ownerId" => $ownerId,
            "ownerName" => $ownerName,
            "ownerPhotoURL" => $ownerPhotoURL,
            "location" => array(
                "latitude" => $location_lat,
                "longitude" => $location_lng
            ),
            "locationAddress" => $locationAddress,
            "createdAt" => (int)$createdAt,
            "updatedAt" => (int)$updatedAt,
            "viewCount" => (int)$viewCount,
            "tags" => json_decode($tags)
        );
        
        array_push($products_arr, $product_item);
    }
    
    http_response_code(200);
    echo json_encode($products_arr);
} else {
    http_response_code(200); // Return empty array instead of 404
    echo json_encode(array());
}
?>
