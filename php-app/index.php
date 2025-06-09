<?php
require_once('config.php');

$conn = getDBConnection();

// Get client IP
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';

// Insert visitor info
$stmt = $conn->prepare("INSERT INTO visitors (ip_address) VALUES (?)");
$stmt->bind_param("s", $ip);
$stmt->execute();

// Fetch recent visitors
$result = $conn->query("SELECT * FROM visitors ORDER BY visit_time DESC LIMIT 10");

echo "<h1>LAMP Stack Demo</h1>";
echo "<h2>Recent Visitors:</h2>";

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        echo "ID: " . $row["id"] . " - IP: " . $row["ip_address"] . " - Visited: " . $row["visit_time"] . "<br>";
    }
} else {
    echo "No visitors yet.";
}

$conn->close();
?>
