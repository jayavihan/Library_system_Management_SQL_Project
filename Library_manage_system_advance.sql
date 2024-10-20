--  Advanced SQL Operations
/*
**Task 13: Identify Members with Overdue Books**  
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.

**Task 14: Update Book Status on Return**  
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

**Task 15: Branch Performance Report**  
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

**Task 16: CTAS: Create a Table of Active Members**  
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

**Task 17: Find Employees with the Most Book Issues Processed**  
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

**Task 18: Identify Members Issuing High-Risk Books**  
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they have issued damaged books.    

**Task 19: Stored Procedure**
Objective:
Create a stored procedure to manage the status of books in a library system.
Description:
Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows:
The stored procedure should take the book_id as an input parameter.
The procedure should first check if the book is available (status = 'yes').
If the book is available, it should be issued, and the status in the books table should be updated to 'no'.
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

**Task 20: Create Table As Select (CTAS)**
Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
    The number of overdue books.
    The total fines, with each days fine calculated at $0.50.
    The number of books issued by each member.
    The resulting table should show:
    Member ID
    Number of overdue books
    Total fines
*/

-- Task 13: Identify Members with Overdue Books**  
-- Write a query to identify members who have overdue books (assume a 30-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue. ,


select members.member_id, members.member_name,books.book_title, issued_status.issued_id,issued_status.issued_date,return_status.return_date,DATEDIFF(  return_status.return_date,issued_status.issued_date) as gap
from members,books,issued_status,return_status
where members.member_id=issued_status.issued_member_id AND books.isbn= issued_status.issued_book_isbn 
AND issued_status.issued_id=return_status.issued_id order by 4;


select members.member_id, members.member_name,books.book_title, issued_status.issued_id,issued_status.issued_date,return_status.return_date
from   issued_status join members
	on issued_status.issued_member_id =members.member_id
    join books
		on books.isbn= issued_status.issued_book_isbn 
        left join return_status
			on return_status.issued_id =issued_status.issued_id
 order by 4;

SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    rs.return_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1;


-- **Task 14: Update Book Status on Return**  
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-451-52994-2';
-- IS104

SELECT * FROM books
WHERE isbn = '978-0-451-52994-2';

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-451-52994-2';

SELECT * FROM return_status
WHERE issued_id = 'IS130';

-- manual enter
INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
VALUES
('RS125', 'IS130', CURRENT_DATE, 'Good');
SELECT * FROM return_status
WHERE issued_id = 'IS130';

DELIMITER //

CREATE PROCEDURE add_return_records(
    IN p_return_id VARCHAR(10), 
    IN p_issued_id VARCHAR(10), 
    IN p_book_quality VARCHAR(10)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    -- Insert into return_status table
    INSERT INTO return_status (return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURDATE(), p_book_quality);

    -- Retrieve book details based on issued_id
    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    -- Update the book's status to 'yes'
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    -- Display a message using SELECT (since MySQL doesn't support RAISE NOTICE)
    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;

END //

DELIMITER ;




-- Testing FUNCTION add_return_records


SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

CALL add_return_records('RS148', 'IS140', 'Good');

CALL add_return_records('RS149', 'IS121', 'Good');

CALL add_return_records('RS150', 'IS123', 'Damaged');

CALL add_return_records('RS151', 'IS139', 'Damaged');

-- **Task 15: Branch Performance Report**  
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

select branch.branch_id,branch.manager_id,
count(issued_status.issued_id) num_issued,
count(return_status.return_id) num_return,
sum(books.rental_price) revenue
 from employees, books,branch,issued_status left join return_status 
on return_status.issued_id=issued_status.issued_id 
where branch.branch_id=employees.branch_id AND
issued_status.issued_emp_id=employees.emp_id AND
books.isbn=issued_status.issued_book_isbn
GROUP by branch_id;

-- --------------------------------------
CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_reports;


-- **Task 16: CTAS: Create a Table of Active Members**  
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.


select members.member_id,members.member_name,issued_status.issued_date from members 
join issued_status on members.member_id=issued_status.issued_member_id
where issued_date> DATE_SUB(curdate(), INTERVAL 2 Month);

-- ------------------------------------------------
CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURdate()- INTERVAL 2 month
                    )
;

SELECT * FROM active_members;


-- **Task 17: Find Employees with the Most Book Issues Processed**  
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.


with super_emp AS(
select issued_emp_id as ids,count(issued_emp_id) counts
from issued_status group by issued_emp_id order by 2 desc limit 3
)
select super_emp.*,emp.emp_name,emp.position from super_emp,employees as emp where emp.emp_id=super_emp.ids;

-- ------------------------------------------------------

-- **Task 18: Identify Members Issuing High-Risk Books**  
-- Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they have issued damaged books.    

with damage_tbl AS(
select members.member_name, books.book_title,return_status.book_quality from members,books,return_status,issued_status
where return_status.issued_id=issued_status.issued_id
AND  issued_status.issued_member_id=members.member_id
AND issued_status.issued_book_isbn=books.isbn  
having return_status.book_quality='Damaged')
select member_name,count(*) 
from damage_tbl group by member_name ;


select * from return_status
where book_quality='Damaged';


/*
Task 19: Stored Procedure Objective: 
Create a stored procedure to manage the status of books in a library system.
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: 
The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

delimiter //
create procedure issue_book(in _issued_id varchar(10),in _issued_member_id varchar(30),in _issued_book_isbn varchar(50),in _issued_emp_id varchar(10))
BEGIN
	DECLARE availability varchar (10);
    
-- chek availability
	select books.status 
    into availability from books 
    where books.isbn=_issued_book_isbn;

-- msg display 
	IF availability='yes' then
		insert into issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id)
        values(_issued_id,_issued_member_id,curdate(),_issued_book_isbn,_issued_emp_id);
        
-- update book status into no
        UPDATE books
        SET status = 'no'
        WHERE isbn = _issued_book_isbn;

        
-- display msg
		select concat('update_successfuly. book_isbn: ',_issued_book_isbn) AS massge;
    
    ELSE
-- Display error message
		SELECT CONCAT('Sorry, the book you requested is unavailable. ISBN: ', _issued_book_isbn) AS message;
    END IF;

END //
DELIMITER ;


SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

-- delete from issued_status where  issued_id='IS155';

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');

CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';

/*
**Task 20: Create Table As Select (CTAS)**
Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
    The number of overdue books.
    The total fines, with each days fine calculated at $0.50.
    The number of books issued by each member.
    The resulting table should show:
    Member ID
    Number of overdue books
    Total fines
*/

with null_return AS(
select members.member_id, members.member_name,books.book_title, issued_status.issued_id,issued_status.issued_date,return_status.return_date,curdate() as today
from   issued_status join members
	on issued_status.issued_member_id =members.member_id
    join books
		on books.isbn= issued_status.issued_book_isbn 
        left join return_status
			on return_status.issued_id =issued_status.issued_id
having return_date is null
 order by 4),
fine as(
 select *,DATEDIFF(null_return. today,null_return.issued_date)as date_diff,(DATEDIFF(null_return. today,null_return.issued_date)-30)*0.5 as due_date_fine
 from null_return
 having date_diff>30) 
 select member_id,member_name,count(*)num_of_books,sum(due_date_fine)total_fine 
 from fine
 group by member_id;