/* Задача 6.
Cкрипты характерных выборок (включающие группировки, JOIN'ы, вложенные таблицы)
*/


-- 1) JOIN. Посчитать, количество заказов с каждого из маркетинговых каналов


SELECT 
	ct.name AS 'Марк.канал',
	COUNT(*) AS 'Кол-во заказов'
FROM channels c
JOIN channel_types ct ON ct.id = c.channel_type_id 
GROUP BY channel_type_id;


-- 2) JOIN. Сколько было сделано заказов и на какую сумму за все время женщинами и мужчинами

SELECT 
	u.gender AS 'Пол',
	COUNT(*) AS 'Кол-во заказов',
	SUM(p.price) AS 'Сумма заказов'
FROM users u 
JOIN orders o ON u.id = o.user_id 
JOIN orders_products op ON o.id = op.order_id 
JOIN products p ON op.product_id = p.id 
GROUP BY u.gender;


-- 3) JOIN. Список товаров, которые купили покупатели с канала 'Google Ads': название товара, цена, количество покупок

SELECT 
	p.name,
	p.price,
	COUNT(*) AS count
FROM products p
JOIN orders_products op ON p.id = op.product_id 
JOIN orders o ON op.order_id = o.id
JOIN channels c ON o.id = c.order_id 
JOIN channel_types ct ON c.channel_type_id = ct.id 
WHERE ct.name = 'Google Ads'
GROUP BY p.name,p.price
ORDER BY count DESC;


-- 4) Вложенный запрос. Вывести список всех товаров в каталоге 'velit'

SELECT 
	id,
	name,
	price
FROM 
	products
WHERE 
	catalog_id = (SELECT id FROM catalogs WHERE name = 'velit');


-- 5) Вложенный запрос. Вывести каталоги, в которых нет товарных позиций

SELECT 
	id, name 
FROM 
	catalogs
WHERE NOT EXISTS (SELECT id, name FROM products WHERE catalog_id = catalogs.id);



-- 6) Вложенный запрос. Вывести среднюю стоимость заказа (ср.чек) за все время


SELECT @income := SUM(price) FROM products WHERE id IN (SELECT product_id FROM orders_products);
SELECT @orders_count := COUNT(DISTINCT order_id) FROM orders_products;

SELECT 
	@income AS 'Общий доход, руб.',
	@orders_count AS 'Кол-во заказов',
	round(@income / @orders_count, 2) AS 'Средний чек, руб.';



/* Задача 7. 
Представления (минимум 2)
*/


DROP VIEW IF EXISTS orders_products_users;
CREATE VIEW orders_products_users AS
SELECT 
	op.created_at AS 'Дата заказа',
	CONCAT(u.firstname, '', u.lastname) AS 'Покупатель',
	p.name AS 'Продукт'
FROM orders_products op 
INNER JOIN products p ON op.product_id = p.id 
INNER JOIN orders o ON op.order_id = o.id 
INNER JOIN users u ON o.user_id = u.id;



DROP VIEW IF EXISTS catalogs_products_discounts;
CREATE VIEW catalogs_products_discounts AS
SELECT
	c.name AS 'Название каталога',
	p.name AS 'Название продукта',
	d.discount AS 'Размер скидки',
	d.started_at AS 'Запуск скидки',
	d.finished_at AS 'Завершение скидки'
FROM catalogs c 
JOIN products p ON c.id = p.catalog_id 
JOIN discounts d ON p.id = d.product_id;




/* Задача 8. 
2 хранимые процедуры и 2 триггера
*/


DELIMITER //


-- ХРАНИМЫЕ ПРОЦЕДУРЫ


-- 1) Возвращает количество строк в таблице orders

DROP PROCEDURE IF EXISTS sp_orders_count// 
CREATE PROCEDURE sp_orders_count (OUT total INT)
BEGIN
SELECT COUNT(*) INTO total FROM orders;
END//

-- CALL sp_orders_count(@total)//


-- 2) Процедура проведения транзакции: вставка продукта на скидку

DROP PROCEDURE IF EXISTS sp_product_discount //
CREATE PROCEDURE sp_product_discount (name VARCHAR(255), 
desription TEXT, price DECIMAL (11,2), discount FLOAT,
started_at DATETIME, finished_at DATETIME,
OUT  tran_result varchar(100))
BEGIN

	DECLARE `_rollback` BIT DEFAULT 0;
	DECLARE code varchar(100);
	DECLARE error_string varchar(100); 


	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	BEGIN
 		SET `_rollback` = 1;
 		GET stacked DIAGNOSTICS CONDITION 1
		code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
		SET tran_result = CONCAT('Ошибка: ', code, ' Транзакция незавершена', error_string);
	END;
	
	
	START TRANSACTION;
	INSERT INTO products (name, desription, price)
	VALUES (name, desription, price);
	
	INSERT INTO discounts (product_id, discount, started_at, finished_at)
	VALUES (last_insert_id(), discount, started_at, finished_at);

	IF `_rollback` THEN
		SET tran_result = 'ROLLBACK';
		ROLLBACK;
	ELSE
		SET tran_result = 'O K';
		COMMIT;
	END IF;

END//


/* CALL sp_product_discount('product_name', 'description', 1500, 0.9, 
'2023-02-14 09:00:00',  '2023-02-24 23:00:00', @tran_result)//
SELECT @tran_result//
*/




-- ТРИГГЕРЫ


/* 1) Проверка даты оформления заказа: если дата заказа больше текущей, автоматически 
устанавливается текущая дата без предупреждения
*/

CREATE TRIGGER IF NOT EXISTS check_order_date_before_insert
BEFORE INSERT
ON orders FOR EACH ROW
BEGIN
	IF NEW.created_at > current_date() THEN
		SET NEW.created_at = current_date();
	END IF;
END;


/* Проверка триггера
INSERT INTO orders (user_id, to_city, created_at, updated_at)
VALUES (NULL, 'Moscow', '2040-01-01 15:06:30', '2023-02-02 15:06:30');
*/



-- 2) Отмена удаления строки с информацией о заказе

CREATE TRIGGER IF NOT EXISTS cancel_order_deletion
BEFORE DELETE 
ON orders FOR EACH ROW
BEGIN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Сработал триггер! Удаление отменено.';
END //


/* Проверка триггера
DELETE FROM orders WHERE id = 1;
 */


DELIMITER ;










































