<?php
require_once('config.php');

$conn = getDBConnection();

// Insert visitor info
$ip = $_SERVER['REMOTE_ADDR'];
$conn->query("INSERT INTO visitors (ip_address) VALUES ('$ip')");

// Fetch recent visitors
$result = $conn->query("SELECT * FROM visitors ORDER BY visit_time DESC LIMIT 10");
?>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>LAMP Stack Demo - Visitors</title>
  <link rel="stylesheet" href="styles.css" />
</head>
<body>

<header>
  <h1>LAMP Stack Visitor Tracker</h1>
</header>

<div class="container">
  <h2>Recent Visitors</h2>
  <?php if ($result && $result->num_rows > 0): ?>
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>IP Address</th>
          <th>Visit Time</th>
        </tr>
      </thead>
      <tbody>
        <?php while($row = $result->fetch_assoc()): ?>
        <tr>
          <td><?= htmlspecialchars($row["id"]) ?></td>
          <td><?= htmlspecialchars($row["ip_address"]) ?></td>
          <td><?= htmlspecialchars($row["visit_time"]) ?></td>
        </tr>
        <?php endwhile; ?>
      </tbody>
    </table>
  <?php else: ?>
    <p>No visitors recorded yet.</p>
  <?php endif; ?>
</div>

<footer>
  &copy; <?= date("Y") ?> LAMP Stack Demo
</footer>

</body>
</html>

<?php $conn->close(); ?>
