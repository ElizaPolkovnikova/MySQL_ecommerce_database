/* 1-3 
1. Составить общее текстовое описание БД и решаемых ею задач;
2. Минимальное количество таблиц - 10;
3. Скрипты создания структуры БД (с первичными ключами, индексами, внешними ключами);
 */



/* База данных магазина электронной коммерции, в которую заносится информация о продуктовых позициях, складе, покупателях, 
 транзакциях, акциях и поддерживается отслеживание эффективности маркетинговых каналов (табл.)
 */


DROP DATABASE IF EXISTS ecom;
CREATE DATABASE ecom;
USE ecom;

DROP TABLE IF EXISTS catalogs;
CREATE TABLE catalogs (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) COMMENT 'Название раздела',
	UNIQUE unique_name(name(10))
) COMMENT = 'Разделы интернет-магазина';


DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL PRIMARY KEY, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	firstname VARCHAR(100) COMMENT 'Имя',
    lastname VARCHAR(100) COMMENT 'Фамилия',
    email VARCHAR(100) UNIQUE,
    phone BIGINT COMMENT 'Телефон',
    gender CHAR(1) COMMENT 'Пол',
    city VARCHAR(255) COMMENT 'Город проживания',
    birthday_on DATE COMMENT 'День рождения',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted bit default b'0',
    
    INDEX users_firstname_lastname_idx(firstname, lastname)
    
) COMMENT = 'Покупатели';



DROP TABLE IF EXISTS products;
CREATE TABLE products (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) COMMENT 'Название',
	desription TEXT COMMENT 'Описание',
	price DECIMAL (11,2) COMMENT 'Цена',
	catalog_id BIGINT UNSIGNED NOT NULL,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	
	KEY index_of_catalog_id(catalog_id),
	FOREIGN KEY (catalog_id) REFERENCES catalogs(id) ON UPDATE CASCADE ON DELETE CASCADE 
	
) COMMENT = 'Товарные позиции';


DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED,
	to_city VARCHAR(255) COMMENT 'Город отправки заказа',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	
	KEY index_of_user_id(user_id),
	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL
	
) COMMENT = 'Заказы';


DROP TABLE IF EXISTS orders_products;
CREATE TABLE orders_products (
	order_id BIGINT UNSIGNED NOT NULL,
	product_id BIGINT UNSIGNED NOT NULL,
	total INT UNSIGNED DEFAULT 1 COMMENT 'Количество заказанных товарных позиций',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	
	PRIMARY KEY (order_id, product_id),
	FOREIGN KEY (order_id) REFERENCES orders(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE
	
) COMMENT = 'Состав заказа';



DROP TABLE IF EXISTS discounts;
CREATE TABLE discounts (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED,
	product_id BIGINT UNSIGNED NOT NULL,
	discount FLOAT UNSIGNED COMMENT 'Величина скидки',
	started_at DATETIME NULL,
	finished_at DATETIME NULL,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	
	KEY index_of_user_id(user_id),
	KEY index_of_product_id(product_id),
	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL,
	FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE
	
) COMMENT = 'Скидки';


DROP TABLE IF EXISTS storehouses;
CREATE TABLE storehouses (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) COMMENT 'Название',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Склады';


DROP TABLE IF EXISTS storehouses_products;
CREATE TABLE storehouses_products (
	storehouse_id BIGINT UNSIGNED NOT NULL,
	product_id BIGINT UNSIGNED NOT NULL,
	value INT UNSIGNED COMMENT 'Запас товарной позиции на складе',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	
	PRIMARY KEY (storehouse_id, product_id),
	FOREIGN KEY (storehouse_id) REFERENCES storehouses(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE
	
) COMMENT = 'Запасы на складе';



-- Маркетинговые каналы, откуда пришли покупатели

DROP TABLE IF EXISTS channel_types;
CREATE TABLE channel_types(
	id SERIAL PRIMARY KEY,
    name VARCHAR(255)COMMENT 'Название маркетингового канала',
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


DROP TABLE IF EXISTS channels; 
CREATE TABLE channels (
	id SERIAL PRIMARY KEY,
	channel_type_id BIGINT UNSIGNED,
	user_id BIGINT UNSIGNED NOT NULL,
	order_id BIGINT UNSIGNED NOT NULL,
	created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (channel_type_id) REFERENCES channel_types(id) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON UPDATE CASCADE ON DELETE CASCADE
);


-- Пакетная вставка в табл. channel_types, остальное заполнение через генератор данных.


INSERT INTO channel_types (id, name, created_at, updated_at)
VALUES
(1, 'Google Ads', '2022-01-31 03:29:46', '2023-02-10 17:25:31'),
(2, 'Facebook Ads', '2022-05-30 23:11:18', '2023-02-10 17:25:31'),
(3, 'VK Ads', '2022-05-07 07:39:15', '2023-02-10 17:25:31'),
(4, 'Bloggers', '2022-03-24 22:57:29', '2023-02-10 17:25:31'),
(5, 'Organic', '2022-07-27 19:16:49', '2023-02-10 17:25:31');





























