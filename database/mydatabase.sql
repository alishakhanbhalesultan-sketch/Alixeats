-- AlixEat database (MySQL 8+)
CREATE DATABASE IF NOT EXISTS alixeat CHARACTER SET utf8mb4;
USE alixeat;

-- 1. Registration / login (store ONLY a bcrypt/argon2 hash, never the plain password)
CREATE TABLE users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  phone         VARCHAR(15)  NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE addresses (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  user_id  INT NOT NULL,
  address  TEXT NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 2. Restaurants and menu
CREATE TABLE restaurants (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(120) NOT NULL,
  category    VARCHAR(60)  NOT NULL,       -- cuisine filter
  about       TEXT,
  rating      DECIMAL(2,1) DEFAULT 4.0,
  eta_minutes VARCHAR(10),
  image_url   VARCHAR(255),
  INDEX (category)
);

CREATE TABLE food_items (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  restaurant_id INT NOT NULL,
  name          VARCHAR(120) NOT NULL,
  description   TEXT,
  price         DECIMAL(8,2) NOT NULL,
  category      ENUM('veg','non','sweet') NOT NULL,
  image_url     VARCHAR(255),
  is_available  BOOLEAN DEFAULT TRUE,
  is_popular    BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
  INDEX (price), FULLTEXT (name, description)
);

-- 3. Cart (persisted server-side)
CREATE TABLE cart_items (
  user_id      INT NOT NULL,
  food_item_id INT NOT NULL,
  quantity     INT NOT NULL CHECK (quantity > 0),
  PRIMARY KEY (user_id, food_item_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (food_item_id) REFERENCES food_items(id)
);

-- 4. Orders, order details and status tracking
CREATE TABLE orders (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  user_id          INT NOT NULL,
  delivery_address TEXT NOT NULL,
  phone            VARCHAR(15) NOT NULL,
  subtotal         DECIMAL(10,2) NOT NULL,
  delivery_fee     DECIMAL(6,2) NOT NULL DEFAULT 40,
  total            DECIMAL(10,2) NOT NULL,
  status           ENUM('Placed','Preparing','Out for delivery','Delivered','Cancelled') DEFAULT 'Placed',
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX (user_id, created_at)
);

CREATE TABLE order_items (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  order_id     INT NOT NULL,
  food_item_id INT NOT NULL,
  name         VARCHAR(120) NOT NULL,      -- snapshot at purchase time
  unit_price   DECIMAL(8,2) NOT NULL,
  quantity     INT NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (food_item_id) REFERENCES food_items(id)
);

CREATE TABLE order_status_history (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  order_id   INT NOT NULL,
  status     VARCHAR(30) NOT NULL,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- ---------- Seed data: 30 famous Indian restaurants and 72 dishes (prices illustrative) ----------
INSERT INTO restaurants (id,name,category,about,rating,eta_minutes) VALUES
(1,'Karim''s','Mughlai','Serving Old Delhi royalty near Jama Masjid since 1913.',4.4,'35-45'),
(2,'Paragon','Biryani','Malabar classic since 1939, famed for its biryani and Kerala seafood.',4.5,'30-40'),
(3,'Bademiya','Kebabs','Colaba''s legendary kebab counter, grilling since 1946.',4.3,'25-35'),
(4,'Britannia & Co.','Parsi','Iconic Parsi café in Ballard Estate since 1923.',4.6,'40-50'),
(5,'Rameshwaram Cafe','South Indian','Bengaluru''s buzzing home of ghee podi idli and filter coffee.',4.7,'20-30'),
(6,'Sardar Pav Bhaji','Street Food','Tardeo''s butter-laden pav bhaji stop since 1966.',4.5,'20-30'),
(7,'Peter Cat','Mughlai','Park Street favourite known for Chelo Kebab.',4.5,'35-45'),
(8,'Bikanervala','Sweets & Snacks','Beloved for chaat, kachori and mithai.',4.3,'25-35'),
(9,'Saravana Bhavan','South Indian','Pure-vegetarian South Indian classics.',4.4,'25-35'),
(10,'Kesar Da Dhaba','Punjabi','Old-school Amritsar dhaba famed for dal and parathas.',4.6,'35-45'),
(11,'Amrik Sukhdev','Punjabi','Highway legend for stuffed parathas with white butter.',4.4,'30-40'),
(12,'Bukhara','Mughlai','Fine-dining tandoor and the celebrated Dal Bukhara.',4.8,'50-60'),
(13,'Arsalan','Biryani','Kolkata biryani with its signature potato and egg.',4.5,'35-45'),
(14,'Hotel Shadab','Biryani','Old City institution for biryani and haleem.',4.4,'35-45'),
(15,'Paradise','Biryani','Hyderabad''s best-known dum biryani house.',4.5,'35-45'),
(16,'Ashok Vada Pav','Street Food','Dadar''s much-loved vada pav stall.',4.3,'15-25'),
(17,'Old Famous Jalebi Wala','Sweets & Snacks','Chandni Chowk jalebis fried fresh and hot.',4.6,'25-35'),
(18,'Ghantewala','Sweets & Snacks','Chandni Chowk mithai shop known for ladoos.',4.4,'30-40'),
(19,'Paranthe Wali Gali','Punjabi','Chandni Chowk lane of stuffed parathas.',4.3,'25-35'),
(20,'Natraj Dahi Bhalla','Street Food','Chandni Chowk chaat stall famed for dahi bhalla.',4.5,'20-30'),
(21,'Nizam''s','Street Food','Kolkata''s home of the kathi roll.',4.4,'25-35'),
(22,'Mahesh Lunch Home','Seafood','Fort''s seafood favourite for crab and pomfret.',4.5,'40-50'),
(23,'Rawat Mishthan Bhandar','Street Food','Jaipur''s pyaaz kachori legend.',4.5,'20-30'),
(24,'Tunday Kababi','Kebabs','Lucknow''s melt-in-mouth galouti kebab.',4.6,'30-40'),
(25,'Prakash Kulfi','Desserts','Lucknow''s classic kulfi falooda.',4.5,'20-30'),
(26,'Ritz Classic','Seafood','Goan thali and fresh fish specialities.',4.3,'35-45'),
(27,'Agashiye','Gujarati','Rooftop Gujarati thali in a heritage haveli.',4.6,'40-50'),
(28,'Kashi Chat Bhandar','Street Food','Varanasi''s famous tamatar chaat.',4.5,'20-30'),
(29,'Kulcha Land','Punjabi','Amritsari kulcha with spicy chole.',4.4,'25-35'),
(30,'Ram Ashraya','South Indian','Matunga''s classic idli-vada breakfast spot.',4.4,'20-30');

INSERT INTO food_items (restaurant_id,name,description,price,category,is_available,is_popular) VALUES
(1,'Mutton Burra',380,'non',1,1),
(1,'Chicken Jahangiri',320,'non',1,0),
(1,'Mutton Nihari',350,'non',1,1),
(1,'Shahi Tukda',140,'sweet',0,0),
(2,'Malabar Chicken Biryani',290,'non',1,1),
(2,'Kerala Parotta (2 pc)',60,'veg',1,0),
(2,'Karimeen Pollichathu',420,'non',1,0),
(2,'Elaneer Payasam',110,'sweet',1,0),
(3,'Seekh Kebab',260,'non',1,1),
(3,'Chicken Tikka Roll',180,'non',1,1),
(3,'Chicken Butter Masala',340,'non',1,0),
(3,'Baida Roti',150,'non',1,0),
(4,'Berry Pulao',490,'non',1,1),
(4,'Sali Boti',420,'non',1,0),
(4,'Caramel Custard',120,'sweet',1,0),
(4,'Raspberry Soda',90,'sweet',1,0),
(5,'Ghee Podi Idli',110,'veg',1,1),
(5,'Ghee Podi Dosa',130,'veg',1,1),
(5,'Filter Coffee',45,'sweet',1,0),
(5,'Bisi Bele Bath',120,'veg',1,0),
(6,'Pav Bhaji',210,'veg',1,1),
(6,'Cheese Pav Bhaji',260,'veg',1,0),
(6,'Masala Pav',150,'veg',1,0),
(6,'Sweet Lassi',90,'sweet',1,0),
(7,'Chelo Kebab',520,'non',1,1),
(7,'Sizzling Brownie',280,'sweet',1,0),
(8,'Raj Kachori',150,'veg',1,1),
(8,'Kaju Katli',220,'sweet',1,0),
(9,'Ghee Roast Dosa',140,'veg',1,1),
(9,'South Indian Meals',220,'veg',1,0),
(10,'Dal Makhani',240,'veg',1,1),
(10,'Amritsari Lassi',110,'sweet',1,0),
(11,'Aloo Paratha',130,'veg',1,1),
(11,'Paneer Paratha',150,'veg',1,0),
(12,'Sikandari Raan',1800,'non',1,1),
(12,'Dal Bukhara',750,'veg',1,0),
(13,'Kolkata Chicken Biryani',320,'non',1,1),
(13,'Chicken Rezala',340,'non',1,0),
(14,'Hyderabadi Mutton Biryani',360,'non',1,1),
(14,'Double Ka Meetha',110,'sweet',1,0),
(15,'Chicken Dum Biryani',330,'non',1,1),
(15,'Mirchi Ka Salan',120,'veg',1,0),
(16,'Vada Pav',35,'veg',1,1),
(16,'Cheese Vada Pav',60,'veg',1,0),
(17,'Jalebi with Rabri',120,'sweet',1,1),
(17,'Imarti',100,'sweet',1,0),
(18,'Motichoor Ladoo',180,'sweet',1,1),
(18,'Rasmalai',160,'sweet',1,0),
(19,'Gobhi Paratha',110,'veg',1,1),
(19,'Mixed Veg Paratha',120,'veg',1,0),
(20,'Dahi Bhalla',90,'veg',1,1),
(20,'Aloo Tikki Chaat',100,'veg',1,0),
(21,'Mutton Kathi Roll',190,'non',1,1),
(21,'Egg Chicken Roll',170,'non',1,0),
(22,'Butter Garlic Crab',1200,'non',1,1),
(22,'Surmai Tawa Fry',650,'non',1,0),
(23,'Pyaaz Kachori',50,'veg',1,1),
(23,'Mawa Kachori',70,'sweet',1,0),
(24,'Galouti Kebab',340,'non',1,1),
(24,'Ulte Tawe Ka Paratha',40,'veg',1,0),
(25,'Kulfi Falooda',150,'sweet',1,1),
(25,'Mango Kulfi',100,'sweet',1,0),
(26,'Goan Fish Thali',420,'non',1,1),
(26,'Prawn Balchao',450,'non',1,0),
(27,'Gujarati Thali',900,'veg',1,1),
(27,'Dhokla',110,'veg',1,0),
(28,'Tamatar Chaat',80,'veg',1,1),
(28,'Palak Chaat',90,'veg',1,0),
(29,'Amritsari Kulcha',150,'veg',1,1),
(29,'Chole Bhature',160,'veg',1,0),
(30,'Idli Vada',100,'veg',1,1),
(30,'Filter Kaapi',40,'sweet',1,0);

-- ---------- Handy queries used by the app ----------
-- Popular restaurants:   SELECT * FROM restaurants ORDER BY rating DESC LIMIT 3;
-- Filter by cuisine:     SELECT * FROM restaurants WHERE category='Biryani' AND rating>=4.5 ORDER BY eta_minutes;
-- Popular food:          SELECT * FROM food_items WHERE is_popular AND is_available;
-- Search + price filter: SELECT * FROM food_items WHERE MATCH(name,description) AGAINST('biryani') AND price BETWEEN 150 AND 300;
-- Cart total:            SELECT SUM(f.price*c.quantity) FROM cart_items c JOIN food_items f ON f.id=c.food_item_id WHERE c.user_id=1;
-- Recent orders:         SELECT * FROM orders WHERE user_id=1 ORDER BY created_at DESC LIMIT 5;
-- Order details:         SELECT * FROM order_items WHERE order_id=1;
-- Update order status:   UPDATE orders SET status='Preparing' WHERE id=1;
--                        INSERT INTO order_status_history (order_id,status) VALUES (1,'Preparing');